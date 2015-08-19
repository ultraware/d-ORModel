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

uses // Delphi
     Data.Datarecord, Data.EnumField, Data.Query, Generics.Collections, Meta.Data,
     Data.Base, DB.Settings, UltraUtilsBasic;

type
{$REGION 'Forward declaration of interfaces'}
   ICaseNext = interface;
   ICaseThen = interface;
   ICaseWhen = interface;
   ICondition = interface;
   IConditionCompareTo = interface;
   IConditionCompareToMulti = interface;
   IConditionCompareToMultiNext = interface;
   ICaseElseCondition = interface;
   IConditionCompareOperator = interface;
   IStatementBase = interface;
   IStatement = interface;
   IStringStatement = interface;
   IBinaryStatement = interface;
   IFloatStatement = interface;
   IIntegerStatement = interface;
   IDateTimeStatement = interface;
   IDateStatement = interface;
   ICustomSQLType = interface;
   IConditionCompare = interface;
   IIsNullNext = interface;
   INullIfNext = interface;
   ICoalesceNext = interface;
   ICoalesceEnd = interface;
   IDateDiffFirstDate = interface;
   IDateDiffSecondDate = interface;
   IDateAddNumber = interface;
   IDate = interface;
   IRound = interface;
   IReplace = interface;
   IReplaceNext = interface;
   INumberOfChars = interface;
   IConcatNext = interface;
   IConcatEnd = interface;
   ISubStringStart = interface;
   ISubStringLength = interface;
   IStuffStart = interface;
   IStuffNumberOfChars = interface;
   IStuffReplaceString = interface;
   ICharIndex = interface;
   ICharIndexStringStatement = interface;
   IPatIndex = interface;
   IDateFrompartsYear = interface;
   IDateFrompartsMonth = interface;
   IDateFrompartsDay = interface;
   IBetweenStart = interface;
   IBetweenEnd = interface;
{$ENDREGION}

{$REGION 'Other types'}
   TConvertSQLType = (csDate, csDateTime, csString, csBit, csFloat, csInt);

   TDatePartType = (ddJaar, ddKwartJaar, ddMaand, ddDagVanJaar, ddDag, ddWeek, ddWeekdag, ddUur, ddMinuut, ddSeconde, ddMiliseconde, ddMicroseconde, ddNanoseconde);

   THashAlgoritme = (haMD2, haMD4, haMD5, haSHA, haSHA1, haSHA2_256, haSHA2_512);

   RGenerateSQLParams = record
   private
      FQuery: IQueryDetails;
      FdbConType: TDBConnectionType;
      FWithAlias: Boolean;
      FField: TBaseField;
      FFieldInGroupByState: Tribool;
   public
      aParams: TVariantArray;

      constructor Create(const aQuery: IQueryDetails; const adbConType: TDBConnectionType; aParams: TVariantArray; const aWithAlias: Boolean; const aField: TBaseField);

      property Query: IQueryDetails read FQuery;
      property dbConType: TDBConnectionType read FdbConType;
      property WithAlias: Boolean read FWithAlias;
      property GenerateField: TBaseField read FField;
   end;
{$ENDREGION}

{$REGION 'Declaration of interfaces'}
   IQueryFieldBuilder = interface
      function New: ICustomSQLType;
      function CurrentFieldCase: ICaseNext;
      function NewSub: ICustomSQLType;
      function GetCustomSQL(var GenerateParams: RGenerateSQLParams): string;
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
      function Spatie: IStringStatement;

      function IsNull(const aField: TBaseField): IIsNullNext; overload;
      function IsNull(const aSubStatement: IStatementBase): IIsNullNext; overload;
      function Coalesce(const aField: TBaseField): ICoalesceNext; overload;
      function Coalesce(const aSubStatement: IStatementBase): ICoalesceNext; overload;
      function NullIf(const aField: TBaseField): INullIfNext; overload;
      function NullIf(const aSubStatement: IStatementBase): INullIfNext; overload;

      function ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement; overload;
      function ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement; overload;

      function OpenBracket: ICustomSQLType;

//      // Bewerkingen op strings
      function Trim(const aField: TBaseField): IStringStatement; overload;
      function Trim(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimLeft(const aField: TBaseField): IStringStatement; overload;
      function TrimLeft(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimRight(const aField: TBaseField): IStringStatement; overload;
      function TrimRight(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Left(const aValue: Variant): INumberOfChars; overload;
      function Left(const aField: TBaseField): INumberOfChars; overload;
      function Left(const aSubStatement: IStringStatement): INumberOfChars; overload;
      function Right(const aValue: Variant): INumberOfChars; overload;
      function Right(const aField: TBaseField): INumberOfChars; overload;
      function Right(const aSubStatement: IStringStatement): INumberOfChars; overload;
      function Upper(const aValue: Variant): IStringStatement; overload;
      function Upper(const aField: TBaseField): IStringStatement; overload;
      function Upper(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Lower(const aValue: Variant): IStringStatement; overload;
      function Lower(const aField: TBaseField): IStringStatement; overload;
      function Lower(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Reverse(const aValue: Variant): IStringStatement; overload;
      function Reverse(const aField: TBaseField): IStringStatement; overload;
      function Reverse(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Replace(const aField: TBaseField): IReplace; overload;
      function Replace(const aSubStatement: IStringStatement): IReplace; overload;
      function Replace(const aField: TBaseField; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
      function Replace(const aSubStatement: IStringStatement; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
      function Concat(const aValue: Variant): IConcatNext; overload;
      function Concat(const aField: TBaseField): IConcatNext; overload;
      function Concat(const aSubStatement: IStringStatement): IConcatNext; overload;
      function SubString(const aValue: Variant): ISubStringStart; overload;
      function SubString(const aField: TBaseField): ISubStringStart; overload;
      function SubString(const aSubStatement: IStringStatement): ISubStringStart; overload;
      function Stuff(const aValue: Variant): IStuffStart; overload;
      function Stuff(const aField: TBaseField): IStuffStart; overload;
      function Stuff(const aSubStatement: IStringStatement): IStuffStart; overload;
      function Replicate(const aValue: Variant): INumberOfChars; overload;
      function Replicate(const aField: TBaseField): INumberOfChars; overload;
      function Replicate(const aSubStatement: IStringStatement): INumberOfChars; overload;
      // informatie van strings
      function Length(const aSubStatement: IStringStatement): IIntegerStatement; overload;
      function Length(const aField: TBaseField): IIntegerStatement; overload;
      function CharIndex(const aValue: Variant): ICharIndex; overload;
      function CharIndex(const aField: TBaseField): ICharIndex; overload;
      function CharIndex(const aSubStatement: IStringStatement): ICharIndex; overload;
      function PatIndex(const aValue: Variant): IPatIndex; overload;
      function PatIndex(const aField: TBaseField): IPatIndex; overload;
      function PatIndex(const aSubStatement: IStringStatement): IPatIndex; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aValue: Variant): IBinaryStatement; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aField: TBaseField): IBinaryStatement; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aSubStatement: IStatementBase): IBinaryStatement; overload;
      function BinaryTohexStr(const aSubStatement: IBinaryStatement): IStringStatement;
      // bewerkingen op getallen
      function Sum(const aField: TBaseField): IFloatStatement; overload;
      function Sum(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Min(const aField: TBaseField): IFloatStatement; overload;
      function Min(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Max(const aField: TBaseField): IFloatStatement; overload;
      function Max(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Count(const aField: TBaseField): IFloatStatement; overload;
      function Count(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function CountDistinct(const aField: TBaseField): IFloatStatement; overload;
      function CountDistinct(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Average(const aField: TBaseField): IFloatStatement; overload;
      function Average(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function CheckSum(const aField: TBaseField): IIntegerStatement; overload;
      function CheckSum(const aSubStatement: IStatementBase): IIntegerStatement; overload;
      function StandardDeviation(const aField: TBaseField): IFloatStatement; overload;
      function StandardDeviation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function StandardDeviationPopulation(const aField: TBaseField): IFloatStatement; overload;
      function StandardDeviationPopulation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Variation(const aField: TBaseField): IFloatStatement; overload;
      function Variation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function VariationPopulation(const aField: TBaseField): IFloatStatement; overload;
      function VariationPopulation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Abs(const aField: TBaseField): IFloatStatement; overload;
      function Abs(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Round(const aField: TBaseField): IRound; overload;
      function Round(const aSubStatement: IFloatStatement): IRound; overload;
      function Round(const aField: TBaseField; const Precision: Integer): IFloatStatement; overload;
      function Round(const aSubStatement: IFloatStatement; const Precision: Integer): IFloatStatement; overload;
      function Floor(const aField: TBaseField): IIntegerStatement; overload;
      function Floor(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
      function Ceiling(const aField: TBaseField): IIntegerStatement; overload;
      function Ceiling(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
      //Bewerkingen van DateTime
      function DateOnly(const aField: TBaseField): IDateStatement; overload;
      function DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement; overload;
      function AlleenCijfers(const aField: TBaseField): IStringStatement; overload;
      function AlleenCijfers(const aSubStatement: IStatementBase): IStringStatement; overload;
      function DateDiff(const Difftype: TDatePartType; const aVanField, aTotField: TBaseField): IIntegerStatement; overload;
      function DateDiff(const Difftype: TDatePartType): IDateDiffFirstDate; overload;
      function DateAdd(const DateAddtype: TDatePartType; const Number: Integer; const Date: TBaseField): IDateTimeStatement; overload;
      function DateAdd(const DateAddtype: TDatePartType): IDateAddNumber; overload;


      function Vandaag: IDateStatement;
      function Morgen: IDateStatement;
      function Nu: IDateTimeStatement;
      function Over1Dag: IDateTimeStatement;
//      //informatie van DateTime velden
      function DatePart(const DatepartType: TDatePartType; const aValue: TDateTime): IIntegerStatement; overload;
      function DatePart(const DatepartType: TDatePartType; const aField: TBaseField): IIntegerStatement; overload;
      function DatePart(const DatepartType: TDatePartType; const aSubStatement: IStatement): IIntegerStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aValue: TDateTime): IStringStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aField: TBaseField): IStringStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aSubStatement: IStatement): IStringStatement; overload;
      function Day(const aValue: TDateTime): IIntegerStatement; overload;
      function Day(const aField: TBaseField): IIntegerStatement; overload;
      function Day(const aSubStatement: IStatement): IIntegerStatement; overload;
      function Month(const aValue: TDateTime): IIntegerStatement; overload;
      function Month(const aField: TBaseField): IIntegerStatement; overload;
      function Month(const aSubStatement: IStatement): IIntegerStatement; overload;
      function Year(const aValue: TDateTime): IIntegerStatement; overload;
      function Year(const aField: TBaseField): IIntegerStatement; overload;
      function Year(const aSubStatement: IStatement): IIntegerStatement; overload;
      function DateFromParts(const aValue: Variant): IDateFrompartsYear; overload;
      function DateFromParts(const aField: TBaseField): IDateFrompartsYear; overload;
      function DateFromParts(const aSubStatement: IIntegerStatement): IDateFrompartsYear; overload;

      procedure SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
   end;

   ICaseEnd = interface
      function CaseEnd: IStatement;
   end;

   ICaseNext = interface(ICaseEnd)
      function When(const aValue: Variant): ICaseThen; overload;
      function When(const aField: TBaseField): ICaseThen; overload;
      function When(const aSubStatement: IStatementBase): ICaseThen; overload;
      function CaseElse(const aValue: Variant): IStatement; overload;
      function CaseElse(const aField: TBaseField): IStatement; overload;
      function CaseElse(const aSubStatement: IStatementBase): IStatement; overload;
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
      function Like: IConditionCompareTo;
      function NotLike: IConditionCompareTo;
      function GreaterOrEqualThen: IConditionCompareTo;
      function GreaterThen: IConditionCompareTo;
      function SmallerOrEqualThen: IConditionCompareTo;
      function SmallerThen: IConditionCompareTo;
      function IsNull: ICondition;
      function IsNotNull: ICondition;
      function InSet: IConditionCompareToMulti;
      function NotInSet: IConditionCompareToMulti;
      function Between: IBetweenStart;
      function NotBetween: IBetweenStart;
   end;

   IConditionCompareTo = interface
      function Waar: ICondition;
      function Onwaar: ICondition;
      function CompareValue(const aValue: Variant): ICondition;
      function CompareField(const aField: TBaseField): ICondition;
      function CompareStatement(const aSubStatement: IStatementBase): ICondition;
   end;

   ISQLPart = interface end;

   IStatementBase = interface(ISQLPart)
   ['{BE9347B8-FEAD-42F4-A9F4-84167A33A113}']
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
   IBinaryStatement = interface(IStatementBase)end;
   IIntegerStatement = interface(IStatementBase)
      function Min: ICustomSQLType;
      function Keer: ICustomSQLType;
      function DelenDoor: ICustomSQLType;
      function Modulo: ICustomSQLType;
   end;
   IFloatStatement = interface(IIntegerStatement)end;
   IDateTimeStatement = interface(IFloatStatement)
      function AsDate: IDateStatement;
   end;
   IDateStatement = interface(IDateTimeStatement)end;

   ICondition = interface(ISQLPart)
      function And_: IConditionCompare;
      function Or_: IConditionCompare;
      function CloseBracket: ICondition;
   end;

   IConditionCompareToMulti = interface
      function Values(const aValues: array of Variant): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of string): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of Integer): IConditionCompareToMultiNext; overload;
      function InSetField(const aField: TBaseField): IConditionCompareToMultiNext;
      function InSetStatement(const aSubStatement: IStatementBase): IConditionCompareToMultiNext;
   end;

   IConditionCompareToMultiNext = interface(ICondition)
      function Values(const aValues: array of Variant): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of string): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of Integer): IConditionCompareToMultiNext; overload;
      function InSetField(const aField: TBaseField): IConditionCompareToMultiNext;
      function InSetStatement(const aSubStatement: IStatementBase): IConditionCompareToMultiNext;
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

   INullIfNext = interface
      function ThenNullIf(const aValue: Variant): IStatement; overload;
      function ThenNullIf(const aField: TBaseField): IStatement; overload;
      function ThenNullIf(const aSubStatement: IStatementBase): IStatement; overload;
   end;

   ICoalesceNext = interface
      function NextCoalesce(const aValue: Variant): ICoalesceEnd; overload;
      function NextCoalesce(const aField: TBaseField): ICoalesceEnd; overload;
      function NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd; overload;
   end;

   ICoalesceEnd = interface(ICoalesceNext)
      function CoalesceEnd: IStatement;
   end;

   IDateDiffFirstDate = interface
      function FirstDate(const aValue: Variant): IDateDiffSecondDate; overload;
      function FirstDate(const aField: TBaseField): IDateDiffSecondDate; overload;
      function FirstDate(const aSubStatement: IDateTimeStatement): IDateDiffSecondDate; overload;
   end;

   IDateDiffSecondDate = interface
      function SecondDate(const aValue: Variant): IIntegerStatement; overload;
      function SecondDate(const aField: TBaseField): IIntegerStatement; overload;
      function SecondDate(const aSubStatement: IDateTimeStatement): IIntegerStatement; overload;
   end;

   IDateAddNumber = interface
      function Number(const aValue: Variant): IDate; overload;
      function Number(const aField: TBaseField): IDate; overload;
      function Number(const aSubStatement: IIntegerStatement): IDate; overload;
   end;

   IDate = interface
      function Date(const aValue: Variant): IDateTimeStatement; overload;
      function Date(const aField: TBaseField): IDateTimeStatement; overload;
      function Date(const aSubStatement: IDateTimeStatement): IDateTimeStatement; overload;
   end;

   IRound = interface
      function Precision(const aValue: Variant): IFloatStatement; overload;
      function Precision(const aField: TBaseField): IFloatStatement; overload;
      function Precision(const aSubStatement: IIntegerStatement): IFloatStatement; overload;
   end;

   IReplace = interface
      function OldPattern(const aValue: Variant): IReplaceNext; overload;
      function OldPattern(const aField: TBaseField): IReplaceNext; overload;
      function OldPattern(const aSubStatement: IStringStatement): IReplaceNext; overload;
   end;

   IReplaceNext = interface
      function NewPattern(const aValue: Variant): IStringStatement; overload;
      function NewPattern(const aField: TBaseField): IStringStatement; overload;
      function NewPattern(const aSubStatement: IStringStatement): IStringStatement; overload;
   end;

   INumberOfChars = interface
      function NumberOfChars(const aValue: Variant): IStringStatement; overload;
      function NumberOfChars(const aField: TBaseField): IStringStatement; overload;
      function NumberOfChars(const aSubStatement: IIntegerStatement): IStringStatement; overload;
   end;

   IConcatNext = interface
      function NextConcat(const aValue: Variant): IConcatEnd; overload;
      function NextConcat(const aField: TBaseField): IConcatEnd; overload;
      function NextConcat(const aSubStatement: IStatementBase): IConcatEnd; overload;
   end;

   IConcatEnd = interface(ICoalesceNext)
      function ConcatEnd: IStatement;
   end;

   ISubStringStart = interface
      function SubStringStart(const aValue: Variant): ISubStringLength; overload;
      function SubStringStart(const aField: TBaseField): ISubStringLength; overload;
      function SubStringStart(const aSubStatement: IStatementBase): ISubStringLength; overload;
   end;

   ISubStringLength = interface
      function StringLength(const aValue: Variant): IStringStatement; overload;
      function StringLength(const aField: TBaseField): IStringStatement; overload;
      function StringLength(const aSubStatement: IStatementBase): IStringStatement; overload;
   end;

   IStuffStart = interface
      function StuffStart(const aValue: Variant): IStuffNumberOfChars; overload;
      function StuffStart(const aField: TBaseField): IStuffNumberOfChars; overload;
      function StuffStart(const aSubStatement: IStatementBase): IStuffNumberOfChars; overload;
   end;

   IStuffNumberOfChars = interface
      function StuffNumberOfChars(const aValue: Variant): IStuffReplaceString; overload;
      function StuffNumberOfChars(const aField: TBaseField): IStuffReplaceString; overload;
      function StuffNumberOfChars(const aSubStatement: IStatementBase): IStuffReplaceString; overload;
   end;

   IStuffReplaceString = interface
      function StuffReplaceString(const aValue: Variant): IStringStatement; overload;
      function StuffReplaceString(const aField: TBaseField): IStringStatement; overload;
      function StuffReplaceString(const aSubStatement: IStatementBase): IStringStatement; overload;
   end;

   ICharIndex = interface
      function SearchCharString(const aValue: Variant): ICharIndexStringStatement; overload;
      function SearchCharString(const aField: TBaseField): ICharIndexStringStatement; overload;
      function SearchCharString(const aSubStatement: IStringStatement): ICharIndexStringStatement; overload;
   end;

   ICharIndexStringStatement = interface(IStringStatement)
      function CharIndexStartPos(const aValue: Variant): IStringStatement; overload;
      function CharIndexStartPos(const aField: TBaseField): IStringStatement; overload;
      function CharIndexStartPos(const aSubStatement: IIntegerStatement): IStringStatement; overload;
   end;

   IPatIndex = interface
      function SearchString(const aValue: Variant): IStringStatement; overload;
      function SearchString(const aField: TBaseField): IStringStatement; overload;
      function SearchString(const aSubStatement: IStringStatement): IStringStatement; overload;
   end;

   IDateFrompartsYear = interface
      function DatePartYear(const aValue: Variant): IDateFrompartsMonth; overload;
      function DatePartYear(const aField: TBaseField): IDateFrompartsMonth; overload;
      function DatePartYear(const aSubStatement: IIntegerStatement): IDateFrompartsMonth; overload;
   end;

   IDateFrompartsMonth = interface
      function DatePartMonth(const aValue: Variant): IDateFrompartsDay; overload;
      function DatePartMonth(const aField: TBaseField): IDateFrompartsDay; overload;
      function DatePartMonth(const aSubStatement: IIntegerStatement): IDateFrompartsDay; overload;
   end;

   IDateFrompartsDay = interface
      function DatePartDay(const aValue: Variant): IDateStatement; overload;
      function DatePartDay(const aField: TBaseField): IDateStatement; overload;
      function DatePartDay(const aSubStatement: IIntegerStatement): IDateStatement; overload;
   end;

   IBetweenStart = interface
      function StartDate(const aValue: Variant): IBetweenEnd; overload;
      function StartDate(const aField: TBaseField): IBetweenEnd overload;
      function StartDate(const aSubStatement: IDateStatement): IBetweenEnd; overload;
   end;

   IBetweenEnd = interface
      function EndDate(const aValue: Variant): ICondition; overload;
      function EndDate(const aField: TBaseField): ICondition; overload;
      function EndDate(const aSubStatement: IDateStatement): ICondition; overload;
   end;

{$ENDREGION}

   TQueryFieldBuilder = class;

   TQueryFieldBuilder = class(TInterfacedObject, IQueryFieldBuilder, ICustomSQLType,
      ICaseNext, ICaseThen, ICaseWhen, ICaseEnd,
      IConditionCompare, IConditionCompareOperator, IConditionCompareTo, IConditionCompareToMulti, IConditionCompareToMultiNext, ICondition, ICaseElseCondition,
      IStatementBase, IStatement, IStringStatement, IIntegerStatement, IFloatStatement, IDateTimeStatement, IDateStatement, IBinaryStatement,
      IIsNullNext, INullIfNext, ICoalesceNext, ICoalesceEnd,
      IDateDiffFirstDate, IDateDiffSecondDate, IDateAddNumber, IDate, IDateFrompartsYear, IDateFrompartsMonth, IDateFrompartsDay,
      IRound, INumberOfChars,
      IReplace, IReplaceNext,
      IConcatNext, IConcatEnd,
      ISubStringStart, ISubStringLength,
      IStuffStart, IStuffNumberOfChars, IStuffReplaceString,
      ICharIndex, ICharIndexStringStatement, IPatIndex,
      IBetweenStart, IBetweenEnd)
   strict private
{$REGION 'Internal types (SQL statements'}
   type
      TSQLStatement = class;
      TSQLStatementClass = class of TSQLStatement;
      TSQLParameter = class
      strict private
         Value: Variant;
         Field: TBaseField;
         Statement: TSQLStatement;
         Builder: TQueryFieldBuilder;
      private
          function StatementIsOfClass(const aClass: TSQLStatementClass): Boolean;
      public
         constructor Create; overload;
         constructor Create(const aValue: Variant); overload;
         constructor Create(const aValue: TBaseField); overload;
         constructor Create(const aValue: TSQLStatement); overload;
         constructor Create(const aValue: TQueryFieldBuilder); overload;
         destructor Destroy; override;

         procedure AddRequiredFields(var Fields: TFieldArray);
         function ToSQL(var GenerateParams: RGenerateSQLParams): string;
      end;

      TParamsList = class(TObjectList<TSQLParameter>);

      TSQLStatement = class abstract
      strict private
         Params: TParamsList;
      protected
         function GetParam(const Index: Integer): TSQLParameter;
         function ParameterCount: Integer;
         function ParamsToSQL(const VanafIndex: Integer; var GenerateParams: RGenerateSQLParams): string;
         function FirstSQLPieceIndex: Integer;

         procedure AddParam(const Value: TSQLParameter);
      public
         constructor Create; virtual;
         destructor Destroy; override;
         procedure AddRequiredFields(var Fields: TFieldArray);
         property Parameter[const Index: Integer]: TSQLParameter read GetParam;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; virtual; abstract;
      end;

      TSQLParamterOnlyStatement = class abstract (TSQLStatement)
      public
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;

      TSQLFunction = class abstract(TSQLStatement)
      private
         FDistinct: Boolean;
      protected
         function SQLFunctionName(const dbConType: TDBConnectionType): string; virtual; abstract;
      public
         constructor Create; override;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;

      TSQLDistinctFunction = class abstract(TSQLFunction)
      public
         constructor Create(const Distinct: Boolean = False); reintroduce;
      end;

      TCompareStatement = class(TSQLParamterOnlyStatement);
      TFieldStatement = class(TSQLParamterOnlyStatement);
      TValueStatement = class(TSQLParamterOnlyStatement);
      TLeftTrimmedStatement = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TRightTrimmedStatement = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TAlleenCijfers = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TMin = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TMax = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TAbs = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDay = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TMonth = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TYear = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TUpper = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TLower = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TChecksum = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TReverse = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TFloor = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TCeiling = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TLength = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TRound = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TLeft = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TRight = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TValuesSet = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TIsNullStatement = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TIsNullCompare = class(TIsNullStatement);
      TIsNullFieldStatement = class(TIsNullStatement);
      TCoalesce = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TNullIf = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TConcat = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TReplace = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TSubstring = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TStuff = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TReplicate = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TCharIndex = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TPatIndex = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDateFromparts = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDateDiff = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDateAdd = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDatepart = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TDateName = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      THashBytes = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TBinaryTohexStr = class(TSQLFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TCount = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TSum = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
	  TAverage = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TStandardDeviation = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TStandardDeviationPopulation = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TVariation = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TVariationPopulation = class(TSQLDistinctFunction)
         function SQLFunctionName(const dbConType: TDBConnectionType): string; override;
      end;
      TBetween = class(TSQLStatement)
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TCaseOf = class(TSQLStatement)
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TCaseWhen = class(TSQLStatement)
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TDateOnly = class(TSQLStatement)
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TCustomSQLStatement = class(TSQLStatement)
      FSQL: string;
      public
         constructor Create(const aSQL: string); reintroduce;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TSQLPieceType = (sqGreaterOrEqualThen, sqGreaterThen, sqSmallerOrEqualThen, sqSmallerThen, sqEqual, sqNotEqual, sqLike, sqNotLike, sqInSet, sqNotInSet, sqIsNull, sqIsNotNull,
         sqPlus, sqMin, sqKeer, sqDelendoor, sqModulo, sqOpenBracket, sqCloseBracket, sqOr, sqAnd, sqNot);
      TSQLPiece = class(TSQLStatement)
      private
         FSQLPieceType: TSQLPieceType;
      public
         constructor Create(const aSQLPieceType: TSQLPieceType); reintroduce;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TSQLDatePiece = class(TSQLStatement)
      private
         FSQLDatePieceType: TDatePartType;
      public
         constructor Create(const aSQLDatePieceType: TDatePartType); reintroduce;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      THashBytesAlgoritm = class(TSQLStatement)
      private
         FHashAlgoritme: THashAlgoritme;
      public
         constructor Create(const aHashAlgoritme: THashAlgoritme); reintroduce;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TConvert = class(TSQLStatement)
      private
         FType: TConvertSQLType;
         FStringSize: Integer;
      public
         constructor Create(const aType: TConvertSQLType; const aStringSize: Integer); reintroduce;
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
      TNU = class(TSQLStatement)
         function ToSQL(var GenerateParams: RGenerateSQLParams): string; override;
      end;
{$ENDREGION}
   var
      FSQLStatement, FLastStatement: TSQLStatement;
      procedure Clear;
      function AddValue(const aValue: Variant): TQueryFieldBuilder;
      function AddField(const aField: TBaseField): TQueryFieldBuilder;
      function AddSubStatement(const aSub: ISQLPart): TQueryFieldBuilder;
      function AddSQLPiece(const aPieceType: TSQLPieceType): TQueryFieldBuilder;
      function AddSQLDatePiece(const aDatePieceType: TDatePartType): TQueryFieldBuilder;
      function AddSQLHashAlgoritme(const aHashAlgoritme: THashAlgoritme): TQueryFieldBuilder;
      function AddParameter(const aValue: TSQLStatement): TQueryFieldBuilder; overload;
      function AddParameter(const aValue: TSQLParameter): TQueryFieldBuilder; overload;

      procedure SetSQLStatement(Value: TSQLStatement);
      property SQLStatement: TSQLStatement read FSQLStatement write SetSQLStatement;
   private
      function GetCustomSQL(var GenerateParams: RGenerateSQLParams): string;
      procedure AddRequiredFields(var RequiredFields: TFieldArray);
      function DefaultIsNullValue(const aField: TBaseField): Variant;
   public
      destructor Destroy; override;
{$REGION 'Implementation of interfaces'}
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

      function TrimmedFieldAndSpace(const aField: TBaseField; const WithIsNull: Boolean = True): IStringStatement;
      function FieldAsStatement(const aField: TBaseField; const WithIsNull: Boolean = False): IStatement;
      function VariantAsStatement(const aValue: Variant): IStatement;
      function Spatie: IStringStatement;

      function IsNull(const aField: TBaseField): IIsNullNext; overload;
      function IsNull(const aSubStatement: IStatementBase): IIsNullNext; overload;
      function Coalesce(const aField: TBaseField): ICoalesceNext; overload;
      function Coalesce(const aSubStatement: IStatementBase): ICoalesceNext; overload;
      function NullIf(const aField: TBaseField): INullIfNext; overload;
      function NullIf(const aSubStatement: IStatementBase): INullIfNext; overload;

      function ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement; overload;
      function ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement; overload;

      function OpenBracket: ICustomSQLType;

//      // Bewerkingen op strings
      function Trim(const aField: TBaseField): IStringStatement; overload;
      function Trim(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimLeft(const aField: TBaseField): IStringStatement; overload;
      function TrimLeft(const aSubStatement: IStringStatement): IStringStatement; overload;
      function TrimRight(const aField: TBaseField): IStringStatement; overload;
      function TrimRight(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Left(const aValue: Variant): INumberOfChars; overload;
      function Left(const aField: TBaseField): INumberOfChars; overload;
      function Left(const aSubStatement: IStringStatement): INumberOfChars; overload;
      function Right(const aValue: Variant): INumberOfChars; overload;
      function Right(const aField: TBaseField): INumberOfChars; overload;
      function Right(const aSubStatement: IStringStatement): INumberOfChars; overload;
      function Upper(const aValue: Variant): IStringStatement; overload;
      function Upper(const aField: TBaseField): IStringStatement; overload;
      function Upper(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Lower(const aValue: Variant): IStringStatement; overload;
      function Lower(const aField: TBaseField): IStringStatement; overload;
      function Lower(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Reverse(const aValue: Variant): IStringStatement; overload;
      function Reverse(const aField: TBaseField): IStringStatement; overload;
      function Reverse(const aSubStatement: IStringStatement): IStringStatement; overload;
      function Replace(const aField: TBaseField): IReplace; overload;
      function Replace(const aSubStatement: IStringStatement): IReplace; overload;
      function Replace(const aField: TBaseField; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
      function Replace(const aSubStatement: IStringStatement; const OldPattern, NewPattern: IStringStatement): IStringStatement; overload;
      function Concat(const aValue: Variant): IConcatNext; overload;
      function Concat(const aField: TBaseField): IConcatNext; overload;
      function Concat(const aSubStatement: IStringStatement): IConcatNext; overload;
      function SubString(const aValue: Variant): ISubStringStart; overload;
      function SubString(const aField: TBaseField): ISubStringStart; overload;
      function SubString(const aSubStatement: IStringStatement): ISubStringStart; overload;
      function Stuff(const aValue: Variant): IStuffStart; overload;
      function Stuff(const aField: TBaseField): IStuffStart; overload;
      function Stuff(const aSubStatement: IStringStatement): IStuffStart; overload;
      function Replicate(const aValue: Variant): INumberOfChars; overload;
      function Replicate(const aField: TBaseField): INumberOfChars; overload;
      function Replicate(const aSubStatement: IStringStatement): INumberOfChars; overload;
      // informatie van strings
      function Length(const aSubStatement: IStringStatement): IIntegerStatement; overload;
      function Length(const aField: TBaseField): IIntegerStatement; overload;
      function CharIndex(const aValue: Variant): ICharIndex; overload;
      function CharIndex(const aField: TBaseField): ICharIndex; overload;
      function CharIndex(const aSubStatement: IStringStatement): ICharIndex; overload;
      function PatIndex(const aValue: Variant): IPatIndex; overload;
      function PatIndex(const aField: TBaseField): IPatIndex; overload;
      function PatIndex(const aSubStatement: IStringStatement): IPatIndex; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aValue: Variant): IBinaryStatement; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aField: TBaseField): IBinaryStatement; overload;
      function HashBytes(const HashAlgoritme: THashAlgoritme; const aSubStatement: IStatementBase): IBinaryStatement; overload;
      function BinaryTohexStr(const aSubStatement: IBinaryStatement): IStringStatement;
//      // bewerkingen op getallen
      function Sum(const aField: TBaseField): IFloatStatement; overload;
      function Sum(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Min(const aField: TBaseField): IFloatStatement; overload;
      function Min(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Max(const aField: TBaseField): IFloatStatement; overload;
      function Max(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Count(const aField: TBaseField): IFloatStatement; overload;
      function Count(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function CountDistinct(const aField: TBaseField): IFloatStatement; overload;
      function CountDistinct(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function Average(const aField: TBaseField): IFloatStatement; overload;
      function Average(const aSubStatement: IStatementBase): IFloatStatement; overload;
      function CheckSum(const aField: TBaseField): IIntegerStatement; overload;
      function CheckSum(const aSubStatement: IStatementBase): IIntegerStatement; overload;
      function StandardDeviation(const aField: TBaseField): IFloatStatement; overload;
      function StandardDeviation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function StandardDeviationPopulation(const aField: TBaseField): IFloatStatement; overload;
      function StandardDeviationPopulation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Variation(const aField: TBaseField): IFloatStatement; overload;
      function Variation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function VariationPopulation(const aField: TBaseField): IFloatStatement; overload;
      function VariationPopulation(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Abs(const aField: TBaseField): IFloatStatement; overload;
      function Abs(const aSubStatement: IFloatStatement): IFloatStatement; overload;
      function Round(const aField: TBaseField): IRound; overload;
      function Round(const aSubStatement: IFloatStatement): IRound; overload;
      function Round(const aField: TBaseField; const Precision: Integer): IFloatStatement; overload;
      function Round(const aSubStatement: IFloatStatement; const Precision: Integer): IFloatStatement; overload;
      function Floor(const aField: TBaseField): IIntegerStatement; overload;
      function Floor(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
      function Ceiling(const aField: TBaseField): IIntegerStatement; overload;
      function Ceiling(const aSubStatement: IFloatStatement): IIntegerStatement; overload;
      //Bewerkingen van DateTime
      function DateOnly(const aField: TBaseField): IDateStatement; overload;
      function DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement; overload;
      function AlleenCijfers(const aField: TBaseField): IStringStatement; overload;
      function AlleenCijfers(const aSubStatement: IStatementBase): IStringStatement; overload;
      function DateDiff(const Difftype: TDatePartType; const aVanField, aTotField: TBaseField): IIntegerStatement; overload;
      function DateDiff(const Difftype: TDatePartType): IDateDiffFirstDate; overload;
      function DateAdd(const DateAddtype: TDatePartType; const Number: Integer; const Date: TBaseField): IDateTimeStatement; overload;
      function DateAdd(const DateAddtype: TDatePartType): IDateAddNumber; overload;

      function Vandaag: IDateStatement;
      function Morgen: IDateStatement;
      function Nu: IDateTimeStatement;
      function Over1Dag: IDateTimeStatement;
//      //informatie van DateTime velden
      function DatePart(const DatepartType: TDatePartType; const aValue: TDateTime): IIntegerStatement; overload;
      function DatePart(const DatepartType: TDatePartType; const aField: TBaseField): IIntegerStatement; overload;
      function DatePart(const DatepartType: TDatePartType; const aSubStatement: IStatement): IIntegerStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aValue: TDateTime): IStringStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aField: TBaseField): IStringStatement; overload;
      function DateName(const DatepartType: TDatePartType; const aSubStatement: IStatement): IStringStatement; overload;
      function Day(const aValue: TDateTime): IIntegerStatement; overload;
      function Day(const aField: TBaseField): IIntegerStatement; overload;
      function Day(const aSubStatement: IStatement): IIntegerStatement; overload;
      function Month(const aValue: TDateTime): IIntegerStatement; overload;
      function Month(const aField: TBaseField): IIntegerStatement; overload;
      function Month(const aSubStatement: IStatement): IIntegerStatement; overload;
      function Year(const aValue: TDateTime): IIntegerStatement; overload;
      function Year(const aField: TBaseField): IIntegerStatement; overload;
      function Year(const aSubStatement: IStatement): IIntegerStatement; overload;
      function DateFromParts(const aValue: Variant): IDateFrompartsYear; overload;
      function DateFromParts(const aField: TBaseField): IDateFrompartsYear; overload;
      function DateFromParts(const aSubStatement: IIntegerStatement): IDateFrompartsYear; overload;

      procedure SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
      { ICaseNext }
      function When(const aValue: Variant): ICaseThen; overload;
      function When(const aField: TBaseField): ICaseThen; overload;
      function When(const aSubStatement: IStatementBase): ICaseThen; overload;
      function CaseElse(const aValue: Variant): IStatement; overload;
      function CaseElse(const aField: TBaseField): IStatement; overload;
      function CaseElse(const aSubStatement: IStatementBase): IStatement; overload;
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
      function Like: IConditionCompareTo;
      function NotLike: IConditionCompareTo;
      function GreaterOrEqualThen: IConditionCompareTo;
      function GreaterThen: IConditionCompareTo;
      function SmallerOrEqualThen: IConditionCompareTo;
      function SmallerThen: IConditionCompareTo;
      function IsNull: ICondition; overload;
      function IsNotNull: ICondition; overload;
      function InSet: IConditionCompareToMulti;
      function NotInSet: IConditionCompareToMulti;
      function Between: IBetweenStart;
      function NotBetween: IBetweenStart;
      { IConditionCompare }
      function Waar: ICondition;
      function Onwaar: ICondition;
      function CompareValue(const aValue: Variant): ICondition;
      function CompareField(const aField: TBaseField): ICondition;
      function CompareStatement(const aSubStatement: IStatementBase): ICondition;
      { IConditionCompareToMulti }
      function Values(const aValues: array of Variant): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of string): IConditionCompareToMultiNext; overload;
      function Values(const aValues: array of Integer): IConditionCompareToMultiNext; overload;
      function InSetField(const aField: TBaseField): IConditionCompareToMultiNext;
      function InSetStatement(const aSubStatement: IStatementBase): IConditionCompareToMultiNext;
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
      { INullIfNext }
      function ThenNullIf(const aValue: Variant): IStatement; overload;
      function ThenNullIf(const aField: TBaseField): IStatement; overload;
      function ThenNullIf(const aSubStatement: IStatementBase): IStatement; overload;
      { ICoalesceNext }
      function NextCoalesce(const aValue: Variant): ICoalesceEnd; overload;
      function NextCoalesce(const aField: TBaseField): ICoalesceEnd; overload;
      function NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd; overload;
      { ICoalesceEnd }
      function CoalesceEnd: IStatement;
      { IDateDiffFirstDate }
      function FirstDate(const aValue: Variant): IDateDiffSecondDate; overload;
      function FirstDate(const aField: TBaseField): IDateDiffSecondDate; overload;
      function FirstDate(const aSubStatement: IDateTimeStatement): IDateDiffSecondDate; overload;
      { IDateDiffSecondDate }
      function SecondDate(const aValue: Variant): IIntegerStatement; overload;
      function SecondDate(const aField: TBaseField): IIntegerStatement; overload;
      function SecondDate(const aSubStatement: IDateTimeStatement): IIntegerStatement; overload;
      { IDateAddNumber }
      function Number(const aValue: Variant): IDate; overload;
      function Number(const aField: TBaseField): IDate; overload;
      function Number(const aSubStatement: IIntegerStatement): IDate; overload;
      { IDate }
      function Date(const aValue: Variant): IDateTimeStatement; overload;
      function Date(const aField: TBaseField): IDateTimeStatement; overload;
      function Date(const aSubStatement: IDateTimeStatement): IDateTimeStatement; overload;
      { IRound }
      function Precision(const aValue: Variant): IFloatStatement; overload;
      function Precision(const aField: TBaseField): IFloatStatement; overload;
      function Precision(const aSubStatement: IIntegerStatement): IFloatStatement; overload;
      { IReplace }
      function OldPattern(const aValue: Variant): IReplaceNext; overload;
      function OldPattern(const aField: TBaseField): IReplaceNext; overload;
      function OldPattern(const aSubStatement: IStringStatement): IReplaceNext; overload;
      { IReplaceNext }
      function NewPattern(const aValue: Variant): IStringStatement; overload;
      function NewPattern(const aField: TBaseField): IStringStatement; overload;
      function NewPattern(const aSubStatement: IStringStatement): IStringStatement; overload;
      { INumberOfChars }
      function NumberOfChars(const aValue: Variant): IStringStatement; overload;
      function NumberOfChars(const aField: TBaseField): IStringStatement; overload;
      function NumberOfChars(const aSubStatement: IIntegerStatement): IStringStatement; overload;
      { IConcatNext }
      function NextConcat(const aValue: Variant): IConcatEnd; overload;
      function NextConcat(const aField: TBaseField): IConcatEnd; overload;
      function NextConcat(const aSubStatement: IStatementBase): IConcatEnd; overload;
      { IConcatEnd }
      function ConcatEnd: IStatement;
      { ISubStringStart }
      function SubStringStart(const aValue: Variant): ISubStringLength; overload;
      function SubStringStart(const aField: TBaseField): ISubStringLength; overload;
      function SubStringStart(const aSubStatement: IStatementBase): ISubStringLength; overload;
      { ISubStringLength }
      function StringLength(const aValue: Variant): IStringStatement; overload;
      function StringLength(const aField: TBaseField): IStringStatement; overload;
      function StringLength(const aSubStatement: IStatementBase): IStringStatement; overload;
      { IStuffStart }
      function StuffStart(const aValue: Variant): IStuffNumberOfChars; overload;
      function StuffStart(const aField: TBaseField): IStuffNumberOfChars; overload;
      function StuffStart(const aSubStatement: IStatementBase): IStuffNumberOfChars; overload;
      { IStuffNumberOfChars }
      function StuffNumberOfChars(const aValue: Variant): IStuffReplaceString; overload;
      function StuffNumberOfChars(const aField: TBaseField): IStuffReplaceString; overload;
      function StuffNumberOfChars(const aSubStatement: IStatementBase): IStuffReplaceString; overload;
      { IStuffReplaceString }
      function StuffReplaceString(const aValue: Variant): IStringStatement; overload;
      function StuffReplaceString(const aField: TBaseField): IStringStatement; overload;
      function StuffReplaceString(const aSubStatement: IStatementBase): IStringStatement; overload;
      { ICharIndex }
      function SearchCharString(const aValue: Variant): ICharIndexStringStatement; overload;
      function SearchCharString(const aField: TBaseField): ICharIndexStringStatement; overload;
      function SearchCharString(const aSubStatement: IStringStatement): ICharIndexStringStatement; overload;
      { ICharIndexStringStatement }
      function CharIndexStartPos(const aValue: Variant): IStringStatement; overload;
      function CharIndexStartPos(const aField: TBaseField): IStringStatement; overload;
      function CharIndexStartPos(const aSubStatement: IIntegerStatement): IStringStatement; overload;
      { IPatIndex }
      function SearchString(const aValue: Variant): IStringStatement; overload;
      function SearchString(const aField: TBaseField): IStringStatement; overload;
      function SearchString(const aSubStatement: IStringStatement): IStringStatement; overload;
      { IDateFrompartsYear }
      function DatePartYear(const aValue: Variant): IDateFrompartsMonth; overload;
      function DatePartYear(const aField: TBaseField): IDateFrompartsMonth; overload;
      function DatePartYear(const aSubStatement: IIntegerStatement): IDateFrompartsMonth; overload;
      { IDateFrompartsMonth }
      function DatePartMonth(const aValue: Variant): IDateFrompartsDay; overload;
      function DatePartMonth(const aField: TBaseField): IDateFrompartsDay; overload;
      function DatePartMonth(const aSubStatement: IIntegerStatement): IDateFrompartsDay; overload;
      { IDateFrompartsDay }
      function DatePartDay(const aValue: Variant): IDateStatement; overload;
      function DatePartDay(const aField: TBaseField): IDateStatement; overload;
      function DatePartDay(const aSubStatement: IIntegerStatement): IDateStatement; overload;
      { IBetweenStart }
      function StartDate(const aValue: Variant): IBetweenEnd; overload;
      function StartDate(const aField: TBaseField): IBetweenEnd overload;
      function StartDate(const aSubStatement: IDateStatement): IBetweenEnd; overload;
      { IBetweenEnd }
      function EndDate(const aValue: Variant): ICondition; overload;
      function EndDate(const aField: TBaseField): ICondition; overload;
      function EndDate(const aSubStatement: IDateStatement): ICondition; overload;
      { IHashBytes }
      function HashBytesInput(const aValue: Variant): IBinaryStatement; overload;
      function HashBytesInput(const aField: TBaseField): IBinaryStatement; overload;
      function HashBytesInput(const aSubStatement: IStatementBase): IBinaryStatement; overload;
{$ENDREGION}
   end;

{$REGION 'Custom SQL Fields'}
   TCustomSQLField = class abstract(TBaseField)
   protected
      FCustomSQLBuilder: IQueryFieldBuilder;
   public
      procedure AfterConstruction; override;
      destructor Destroy; override;

      property ValueAsVariant : Variant   read GetValueAsVariant;  // read-only maken

      property CustomSQL: IQueryFieldBuilder read FCustomSQLBuilder;
      function GetCustomSQL(const aQuery: IQueryDetails; const dbConType: TDBConnectionType; var aParams: TVariantArray; const WithAlias: Boolean): string;
      function GetRequiredFields: TFieldArray;
   end;
   TCustomSQLFieldClass = class of TCustomSQLField;

   TSQLStringField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedString: string read GetValueAsString;
      property ValueOrEmptyString;
      property IsEmptyString;
   end;

   TSQLIntegerField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedInteger: Integer read GetValueAsInteger;
      property ValueOrZero: Integer read GetIntValueOrZero;
   end;

   TSQLDoubleField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedDouble: Double read GetValueAsDouble;
   end;

   TSQLPercentageField = class(TSQLDoubleField) 
   public
      procedure SetPercentageSQL(const Field1, Field2: TBaseField);
   end;

   TSQLCurrencyField = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   public
      property TypedCurrency: Currency read GetValueAsCurrency;
   end;

   TSQLDateTimeFieldBase = class(TCustomSQLField)
   protected
      function GetFieldType: TFieldType; override;
   end;

   TSQLDateTimeField = class(TSQLDateTimeFieldBase)
   public
      property TypedDateTime: TDateTime read GetValueAsDateTime;
   end;

   TSQLDateField = class(TSQLDateTimeFieldBase)
   public
      property TypedDate: TDate read GetValueAsDate;
   end;

   TSQLTimeField = class(TSQLDateTimeFieldBase)
   public
      property TypedTime: TTime read GetValueAsTime;
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
{$ENDREGION}

{$REGION 'Global functions'}
   function SQL_Vandaag_Field: TSQLDateField;
   function SQL_Nu_Field: TSQLDateTimeField;
   function SQL_Vandaag_Plus_1_Field: TSQLDateField;
   function SQL_Nu_Plus_1_Field: TSQLDateTimeField;
   function Dummy: TSQLIntegerField;

   function GetFieldTag(const Index: Integer): string;
   function VariantToSQLString(const aValue: Variant): string;

   function AddCustomStringField(DataRecord: TDataRecord; const Name: string): TSQLStringField;
   function AddCustomIntegerField(DataRecord: TDataRecord; const Name: string): TSQLIntegerField;
   function AddCustomDoubleField(DataRecord: TDataRecord; const Name: string): TSQLDoubleField;
   function AddCustomPercentageField(DataRecord: TDataRecord; const Name: string): TSQLPercentageField;
   function AddCustomDateTimeField(DataRecord: TDataRecord; const Name: string): TSQLDateTimeField;
   function AddCustomDateField(DataRecord: TDataRecord; const Name: string): TSQLDateField;
   function AddCustomTimeField(DataRecord: TDataRecord; const Name: string): TSQLTimeField;
   function AddCustomBooleanField(DataRecord: TDataRecord; const Name: string): TSQLBooleanField;
   procedure RemoveCustomSQLField(Field: TCustomSQLField; DataRecord: TDataRecord; const DestroyField: Boolean = True);
{$ENDREGION}

implementation

uses // Delphi
     Math, StrUtils, SysUtils, Variants, DB.SQLBuilder
     // Shared
     ;

type
   // Globaal datarecord met 'velden' zonder tabel
   TDatabaseSQLVelden = class(TMultiDataRecord)
   private
      function GetSQLDateTimeField(index: Integer): TSQLDateTimeField;
      function GetSQLDateField(index: Integer): TSQLDateField;
      function GetSQLIntegerField(index: Integer): TSQLIntegerField;
   public
      procedure AfterConstruction; override;
   published
      property  SQL_Now_Field             : TSQLDateTimeField            index   0 read GetSQLDateTimeField;
      property  SQL_TodayField            : TSQLDateField                index   1 read GetSQLDateField;
      property  SQL_Now_Plus_1_Field      : TSQLDateTimeField            index   2 read GetSQLDateTimeField;
      property  SQL_Today_Plus_1Field     : TSQLDateField                index   3 read GetSQLDateField;
      property  Dummy                     : TSQLIntegerField             index   4 read GetSQLIntegerField;
   end;

var GDatabaseSQLVelden: TDatabaseSQLVelden;
    DatabaseCompatLevel: Integer = 2008; // zolang MW dit nog niet kan bepalen

const
   FieldTag                = '$f%d$';

{$REGION 'Global function'}
function AddExtraField(DataRecord: TDataRecord; const Name: string; const aFieldType: TFieldType; const CustomSQLFieldClass: TCustomSQLFieldClass = nil): TCustomSQLField;
var Index: Integer;
    TableFieldMeta: TBaseTableAttribute;
    FieldMeta: TTypedMetaField;
begin
   Index := DataRecord.Count;
   TableFieldMeta := TBaseTableAttribute.Create(nil);
   FieldMeta := TTypedMetaField.Create(Name, aFieldType, false, '', 0, 0);
   TableFieldMeta.FieldMetaData := FieldMeta;
   if Assigned(CustomSQLFieldClass) then
      Result := CustomSQLFieldClass.Create  (Name, DataRecord, Index, TableFieldMeta)
   else
   begin
   case aFieldType of
      ftFieldString:                Result := TSQLStringField.Create  (Name, DataRecord, Index, TableFieldMeta);
      ftFieldBoolean:               Result := TSQLBooleanField.Create (Name, DataRecord, Index, TableFieldMeta);
      ftFieldDouble:                Result := TSQLDoubleField.Create  (Name, DataRecord, Index, TableFieldMeta);
      ftFieldInteger, ftFieldID:    Result := TSQLIntegerField.Create (Name, DataRecord, Index, TableFieldMeta);
      ftFieldDateTime:              Result := TSQLDateTimeField.Create(Name, DataRecord, Index, TableFieldMeta);
   else
      Result := TCustomSQLField.Create(Name, DataRecord, Index, TableFieldMeta);
   end;
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

function AddCustomPercentageField(DataRecord: TDataRecord; const Name: string): TSQLPercentageField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDouble, TSQLPercentageField) as TSQLPercentageField;
end;

function AddCustomDateTimeField(DataRecord: TDataRecord; const Name: string): TSQLDateTimeField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDateTime) as TSQLDateTimeField;
end;

function AddCustomDateField(DataRecord: TDataRecord; const Name: string): TSQLDateField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDateTime, TSQLDateField) as TSQLDateField;
end;

function AddCustomTimeField(DataRecord: TDataRecord; const Name: string): TSQLTimeField;
begin
   Result := AddExtraField(DataRecord, Name, ftFieldDateTime, TSQLTimeField) as TSQLTimeField;
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

function SQL_Nu_Field: TSQLDateTimeField;
begin
   Result := GDatabaseSQLVelden.SQL_Now_Field;
end;

function SQL_Vandaag_Field: TSQLDateField;
begin
   Result := GDatabaseSQLVelden.SQL_TodayField;
end;

function SQL_Vandaag_Plus_1_Field: TSQLDateField;
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
{$ENDREGION}

{$REGION 'TQueryFieldBuilder'}
   { TQueryFieldBuilder }

   { Public }

destructor TQueryFieldBuilder.Destroy;
begin
   Clear;
   inherited;
end;

   { strict Private }
procedure TQueryFieldBuilder.Clear;
begin
   FLastStatement := nil; // is alleen een verwijziging
   if Assigned(SQLStatement) then
      FreeAndNil(FSQLStatement);
end;

function TQueryFieldBuilder.AddValue(const aValue: Variant): TQueryFieldBuilder;
var Statement: IStatementBase;
begin
   if VarIsType(aValue, varUnknown) then
   begin
      // per ongeluk IDateStatement ipv IDateTimeStatment?
      if Supports(aValue, IStatementBase, Statement) then
         Result := AddSubStatement(Statement)
   else
      begin
         Assert(False,'Onbekend type');
         Result := nil;
   end;
   end
   else
      Result := AddParameter(TSQLParameter.Create(aValue));
end;

function TQueryFieldBuilder.AddField(const aField: TBaseField): TQueryFieldBuilder;
begin
   Result := AddParameter(TSQLParameter.Create(aField));
end;

function TQueryFieldBuilder.AddSubStatement(const aSub: ISQLPart): TQueryFieldBuilder;
begin
   Result := AddParameter(TSQLParameter.Create(aSub as TQueryFieldBuilder));
end;

function TQueryFieldBuilder.AddSQLPiece(const aPieceType: TSQLPieceType): TQueryFieldBuilder;
begin
   Result := AddParameter(TSQLPiece.Create(aPieceType));
end;

function TQueryFieldBuilder.AddSQLDatePiece(const aDatePieceType: TDatePartType): TQueryFieldBuilder;
begin
   Result := AddParameter(TSQLDatePiece.Create(aDatePieceType));
end;

function TQueryFieldBuilder.AddSQLHashAlgoritme(const aHashAlgoritme: THashAlgoritme): TQueryFieldBuilder;
begin
   Result := AddParameter(THashBytesAlgoritm.Create(aHashAlgoritme));
end;

function TQueryFieldBuilder.AddParameter(const aValue: TSQLStatement): TQueryFieldBuilder;
begin
   Result := AddParameter(TSQLParameter.Create(aValue));
end;

function TQueryFieldBuilder.AddParameter(const aValue: TSQLParameter): TQueryFieldBuilder;
begin
   Assert(Assigned(FLastStatement));
   (FLastStatement as TSQLStatement).AddParam(aValue);
   Result := Self
end;

procedure TQueryFieldBuilder.SetSQLStatement(Value: TSQLStatement);
begin
   if Assigned(FSQLStatement) then
      AddParameter(Value)
   else
      FSQLStatement := Value;
   FLastStatement := Value;
end;

   { Private }
function TQueryFieldBuilder.GetCustomSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   Assert(Assigned(SQLStatement));
   Result := SQLStatement.ToSQL(GenerateParams);
end;

procedure TQueryFieldBuilder.AddRequiredFields(var RequiredFields: TFieldArray);
begin
   if Assigned(SQLStatement) then
      SQLStatement.AddRequiredFields(RequiredFields);
end;

function TQueryFieldBuilder.DefaultIsNullValue(const aField: TBaseField): Variant;
begin
   case aField.FieldType of
      ftFieldID,
      ftFieldBoolean,
      ftFieldDouble,
      ftFieldCurrency,
      ftFieldInteger,
      ftFieldDateTime: Result := 0;
   else
       Result := '';
   end;
end;

{$REGION 'Implementation of interfaces'}
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
var Sub: TQueryFieldBuilder;
begin
   Sub := TQueryFieldBuilder.Create;
   Result := Sub.New;
   Inc(Sub.FRefCount);
end;

{ ICustomSQLType }

function TQueryFieldBuilder.AlleenCijfers(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TAlleenCijfers.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.AlleenCijfers(const aSubStatement: IStatementBase): IStringStatement;
begin
   SQLStatement := TAlleenCijfers.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CaseFieldOf(const aField: TBaseField): ICaseNext;
begin
   SQLStatement := TCaseOf.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CaseFieldOf(const aSubStatement: IStatementBase): ICaseNext;
begin
   SQLStatement := TCaseOf.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CaseWhen(const aCondition: ICondition): ICaseWhen;
begin
   SQLStatement := TCaseWhen.Create;
   Result := AddSubStatement(aCondition);
end;

function TQueryFieldBuilder.FieldCompare(const aField: TBaseField; const WithIsNull: Boolean = False): IConditionCompareOperator;
begin
   if WithIsNull then
      SQLStatement := TIsNullCompare.Create
   else
      SQLStatement := TCompareStatement.Create;
   Result := AddField(aField);
   if WithIsNull then
      Result := AddValue(DefaultIsNullValue(aField));
end;

function TQueryFieldBuilder.StatementCompare(const aSubStatement: IStatementBase): IConditionCompareOperator;
begin
   SQLStatement := TCompareStatement.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.FieldAsStatement(const aField: TBaseField; const WithIsNull: Boolean = False): IStatement;
begin
   if WithIsNull then
      SQLStatement := TIsnullFieldStatement.Create
   else
      SQLStatement := TFieldStatement.Create;
   Result := AddField(aField);
   if WithIsNull then
      Result := AddValue(DefaultIsNullValue(aField));
end;

function TQueryFieldBuilder.VariantAsStatement(const aValue: Variant): IStatement;
begin
   SQLStatement := TValueStatement.Create;
   Result := AddValue(aValue);
end;

function  TQueryFieldBuilder.Spatie: IStringStatement;
begin
   Result := VariantAsStatement(' ').AsString;
end;

function TQueryFieldBuilder.TrimmedFieldAndSpace(const aField: TBaseField; const WithIsNull: Boolean = True): IStringStatement;
begin
   if WithIsNull then
      Result := TrimLeft(NewSub.TrimRight(NewSub.IsNull(aField).ThenIsNull(DefaultIsNullValue(aField)).AsString).Plus.Spatie)
   else
      Result := TrimLeft(NewSub.TrimRight(NewSub.FieldAsStatement(aField).AsString).Plus.Spatie);
end;

function TQueryFieldBuilder.Trim(const aField: TBaseField): IStringStatement;
begin
   Result := TrimLeft(NewSub.TrimRight(aField));
end;

function TQueryFieldBuilder.Trim(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := TrimLeft(NewSub.TrimRight(aSubStatement));
end;

function TQueryFieldBuilder.TrimLeft(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TLeftTrimmedStatement.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.TrimLeft(const aSubStatement: IStringStatement): IStringStatement;
begin
   SQLStatement := TLeftTrimmedStatement.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.TrimRight(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TRightTrimmedStatement.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.TrimRight(const aSubStatement: IStringStatement): IStringStatement;
begin
   SQLStatement := TRightTrimmedStatement.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Left(const aValue: Variant): INumberOfChars;
begin
   SQLStatement := TLeft.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Left(const aField: TBaseField): INumberOfChars;
begin
   SQLStatement := TLeft.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Left(const aSubStatement: IStringStatement): INumberOfChars;
begin
   SQLStatement := TLeft.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Right(const aValue: Variant): INumberOfChars;
begin
   SQLStatement := TRight.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Right(const aField: TBaseField): INumberOfChars;
begin
   SQLStatement := TRight.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Right(const aSubStatement: IStringStatement): INumberOfChars;
begin
   SQLStatement := TRight.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Upper(const aValue: Variant): IStringStatement;
begin
   SQLStatement := TUpper.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Upper(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TUpper.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Upper(const aSubStatement: IStringStatement): IStringStatement;
begin
   SQLStatement := TUpper.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Lower(const aValue: Variant): IStringStatement;
begin
   SQLStatement := TLower.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Lower(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TLower.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Lower(const aSubStatement: IStringStatement): IStringStatement;
begin
   SQLStatement := TLower.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Reverse(const aValue: Variant): IStringStatement;
begin
   SQLStatement := TReverse.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Reverse(const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TReverse.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Reverse(const aSubStatement: IStringStatement): IStringStatement;
begin
   SQLStatement := TReverse.Create;
   Result := AddSubStatement(aSubStatement);
end;

procedure TQueryFieldBuilder.SetCustomSQL(const aSQL: string; Fields: array of TBaseField);
var aField: TBaseField;
begin
   Clear;
   SQLStatement := TCustomSQLStatement.Create(aSQL);
   for aField in Fields do
      AddField(aField);
end;

{ ICaseNext }
function TQueryFieldBuilder.When(const aValue: Variant): ICaseThen;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.When(const aField: TBaseField): ICaseThen;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.When(const aSubStatement: IStatementBase): ICaseThen;
begin
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CaseElse(const aValue: Variant): IStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CaseElse(const aField: TBaseField): IStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CaseElse(const aSubStatement: IStatementBase): IStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { ICaseWhen }
function TQueryFieldBuilder.CaseCompareThen(const aValue: Variant): ICaseNext;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CaseCompareThen(const aField: TBaseField): ICaseNext;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CaseCompareThen(const aSubStatement: IStatementBase): ICaseNext;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { ICaseThenEnd }
function TQueryFieldBuilder.ThenEnd(const aValue: Variant): IStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.ThenEnd(const aField: TBaseField): IStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.ThenEnd(const aSubStatement: IStatementBase): IStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.ThenIsNull(const aValue: Variant): IStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.ThenIsNull(const aField: TBaseField): IStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.ThenIsNull(const aSubStatement: IStatementBase): IStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ INullIfNext }
function TQueryFieldBuilder.ThenNullIf(const aValue: Variant): IStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.ThenNullIf(const aField: TBaseField): IStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.ThenNullIf(const aSubStatement: IStatementBase): IStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CaseThen(const aValue: Variant): ICaseElseCondition;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CaseThen(const aField: TBaseField): ICaseElseCondition;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CaseThen(const aSubStatement: IStatementBase): ICaseElseCondition;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { IConditionCompare }
function TQueryFieldBuilder.OpenBracketCompare: IConditionCompare;
begin
   Result := AddSQLPiece(sqOpenBracket);
end;

function TQueryFieldBuilder.Value(const aValue: Variant): IConditionCompareOperator;
begin
   SQLStatement := TValueStatement.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Field(const aField: TBaseField): IConditionCompareOperator;
begin
   SQLStatement := TFieldStatement.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Statement(const aSubStatement: IStatementBase): IConditionCompareOperator;
begin
   SQLStatement := TFieldStatement.Create;
   Result := AddSubStatement(aSubStatement);
end;

      { IConditionCompareOperator }
function TQueryFieldBuilder.Equal: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqEqual);
end;

function TQueryFieldBuilder.NotEqual: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqNotEqual);
end;

function TQueryFieldBuilder.Like: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqLike);
end;

function TQueryFieldBuilder.NotLike: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqNotLike);
end;

function TQueryFieldBuilder.GreaterOrEqualThen: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqGreaterOrEqualThen);
end;

function TQueryFieldBuilder.GreaterThen: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqGreaterThen);
end;

function TQueryFieldBuilder.Sum(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TSum.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Sum(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TSum.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Min(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TMin.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Min(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TMin.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Max(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TMax.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Max(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TMax.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Floor(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TFloor.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Floor(const aSubStatement: IFloatStatement): IIntegerStatement;
begin
   SQLStatement := TFloor.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Ceiling(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TCeiling.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Ceiling(const aSubStatement: IFloatStatement): IIntegerStatement;
begin
   SQLStatement := TCeiling.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Count(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TCount.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Count(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TCount.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CountDistinct(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TCount.Create(True);
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CountDistinct(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TCount.Create(True);
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Average(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TAverage.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Average(const aSubStatement: IStatementBase): IFloatStatement;
begin
   SQLStatement := TAverage.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CheckSum(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TChecksum.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Length(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TLength.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Length(const aSubStatement: IStringStatement): IIntegerStatement;
begin
   SQLStatement := TLength.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CheckSum(const aSubStatement: IStatementBase): IIntegerStatement;
begin
   SQLStatement := TChecksum.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.StandardDeviation(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TStandardDeviation.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StandardDeviation(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   SQLStatement := TStandardDeviation.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.StandardDeviationPopulation(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TStandardDeviationPopulation.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StandardDeviationPopulation(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   SQLStatement := TStandardDeviationPopulation.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Variation(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TVariation.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Variation(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   SQLStatement := TVariation.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.VariationPopulation(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TVariationPopulation.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.VariationPopulation(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   SQLStatement := TVariationPopulation.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Abs(const aField: TBaseField): IFloatStatement;
begin
   SQLStatement := TAbs.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Abs(const aSubStatement: IFloatStatement): IFloatStatement;
begin
   SQLStatement := TAbs.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.IsNull(const aField: TBaseField): IIsNullNext;
begin
   SQLStatement := TIsNullStatement.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.IsNull(const aSubStatement: IStatementBase): IIsNullNext;
begin
   SQLStatement := TIsNullStatement.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.SmallerOrEqualThen: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqSmallerOrEqualThen);
end;

function TQueryFieldBuilder.SmallerThen: IConditionCompareTo;
begin
   Result := AddSQLPiece(sqSmallerThen);
end;

function TQueryFieldBuilder.IsNull: ICondition;
begin
   Result := AddSQLPiece(sqIsNull);
end;

function TQueryFieldBuilder.IsNotNull: ICondition;
begin
   Result := AddSQLPiece(sqIsNotNull);
end;

function TQueryFieldBuilder.InSet: IConditionCompareToMulti;
begin
   Result := AddSQLPiece(sqInSet);
   SQLStatement := TValuesSet.Create;
end;

function TQueryFieldBuilder.NotInSet: IConditionCompareToMulti;
begin
   Result := AddSQLPiece(sqNotInSet);
   SQLStatement := TValuesSet.Create;
end;

function TQueryFieldBuilder.Between: IBetweenStart;
begin
   Result := Self;
   SQLStatement := TBetween.Create;
end;

function TQueryFieldBuilder.NotBetween: IBetweenStart;
begin
   SQLStatement := TBetween.Create;
   Result := AddSQLPiece(sqNot);
end;

      { IConditionCompare }
function TQueryFieldBuilder.Coalesce(const aField: TBaseField): ICoalesceNext;
begin
   SQLStatement := TCoalesce.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Coalesce(const aSubStatement: IStatementBase): ICoalesceNext;
begin
   SQLStatement := TCoalesce.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.ConvertTo(const aType: TConvertSQLType; const aField: TBaseField; const StringSize: Integer = 0): IStatement;
begin
   SQLStatement := TConvert.Create(aType, StringSize);
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NullIf(const aField: TBaseField): INullIfNext;
begin
   SQLStatement := TNullIf.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NullIf(const aSubStatement: IStatementBase): INullIfNext;
begin
   SQLStatement := TNullIf.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.ConvertTo(const aType: TConvertSQLType; const aSubStatement: IStatementBase; const StringSize: Integer = 0): IStatement;
begin
   SQLStatement := TConvert.Create(aType, StringSize);
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Round(const aField: TBaseField; const Precision: Integer): IFloatStatement;
begin
   Result := Round(aField).Precision(Precision);
end;

function TQueryFieldBuilder.Round(const aSubStatement: IFloatStatement; const Precision: Integer): IFloatStatement;
begin
   Result := Round(aSubStatement).Precision(Precision);
end;

function TQueryFieldBuilder.Round(const aField: TBaseField): IRound;
begin
   SQLStatement := TRound.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Round(const aSubStatement: IFloatStatement): IRound;
begin
   SQLStatement := TRound.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Replace(const aField: TBaseField; const OldPattern, NewPattern: IStringStatement): IStringStatement;
begin
   Result := Replace(aField).OldPattern(OldPattern).NewPattern(NewPattern);
end;

function TQueryFieldBuilder.Replace(const aSubStatement, OldPattern, NewPattern: IStringStatement): IStringStatement;
begin
   Result := Replace(aSubStatement).OldPattern(OldPattern).NewPattern(NewPattern);
end;

function TQueryFieldBuilder.Replace(const aField: TBaseField): IReplace;
begin
   SQLStatement := TReplace.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Replace(const aSubStatement: IStringStatement): IReplace;
begin
   SQLStatement := TReplace.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Concat(const aValue: Variant): IConcatNext;
begin
   SQLStatement := TConcat.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Concat(const aField: TBaseField): IConcatNext;
begin
   SQLStatement := TConcat.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Concat(const aSubStatement: IStringStatement): IConcatNext;
begin
   SQLStatement := TConcat.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.SubString(const aValue: Variant): ISubStringStart;
begin
   SQLStatement := TSubstring.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.SubString(const aField: TBaseField): ISubStringStart;
begin
   SQLStatement := TSubstring.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.SubString(const aSubStatement: IStringStatement): ISubStringStart;
begin
   SQLStatement := TSubstring.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Stuff(const aValue: Variant): IStuffStart;
begin
   SQLStatement := TStuff.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Stuff(const aField: TBaseField): IStuffStart;
begin
   SQLStatement := TStuff.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Stuff(const aSubStatement: IStringStatement): IStuffStart;
begin
   SQLStatement := TStuff.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Replicate(const aValue: Variant): INumberOfChars;
begin
   SQLStatement := TReplicate.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Replicate(const aField: TBaseField): INumberOfChars;
begin
   SQLStatement := TReplicate.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Replicate(const aSubStatement: IStringStatement): INumberOfChars;
begin
   SQLStatement := TReplicate.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.CharIndex(const aValue: Variant): ICharIndex;
begin
   SQLStatement := TCharIndex.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CharIndex(const aField: TBaseField): ICharIndex;
begin
   SQLStatement := TCharIndex.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CharIndex(const aSubStatement: IStringStatement): ICharIndex;
begin
   SQLStatement := TCharIndex.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.PatIndex(const aValue: Variant): IPatIndex;
begin
   SQLStatement := TPatIndex.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.PatIndex(const aField: TBaseField): IPatIndex;
begin
   SQLStatement := TPatIndex.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.PatIndex(const aSubStatement: IStringStatement): IPatIndex;
begin
   SQLStatement := TPatIndex.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.HashBytes(const HashAlgoritme: THashAlgoritme; const aValue: Variant): IBinaryStatement;
begin
   SQLStatement := THashBytes.Create;
   AddSQLHashAlgoritme(HashAlgoritme);
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.HashBytes(const HashAlgoritme: THashAlgoritme; const aField: TBaseField): IBinaryStatement;
begin
   SQLStatement := THashBytes.Create;
   AddSQLHashAlgoritme(HashAlgoritme);
   Result := AddField(aField);
end;

function TQueryFieldBuilder.HashBytes(const HashAlgoritme: THashAlgoritme; const aSubStatement: IStatementBase): IBinaryStatement;
begin
   SQLStatement := THashBytes.Create;
   AddSQLHashAlgoritme(HashAlgoritme);
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.BinaryTohexStr(const aSubStatement: IBinaryStatement): IStringStatement;
begin
   SQLStatement := TBinaryTohexStr.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.DateOnly(const aField: TBaseField): IDateStatement;
begin
   SQLStatement := TDateOnly.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DateOnly(const aSubStatement: IDateTimeStatement): IDateStatement;
begin
   SQLStatement := TDateOnly.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.DateDiff(const Difftype: TDatePartType; const aVanField, aTotField: TBaseField): IIntegerStatement;
begin
   Result := DateDiff(Difftype).FirstDate(aVanField).SecondDate(aTotField);
end;

function TQueryFieldBuilder.DateDiff(const Difftype: TDatePartType): IDateDiffFirstDate;
begin
   SQLStatement := TDateDiff.Create;
   Result := AddSQLDatePiece(DiffType);
end;

function TQueryFieldBuilder.DateFromParts(const aValue: Variant): IDateFrompartsYear;
begin
   SQLStatement := TDateFromparts.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DateFromParts(const aField: TBaseField): IDateFrompartsYear;
begin
   SQLStatement := TDateFromparts.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DateFromParts(const aSubStatement: IIntegerStatement): IDateFrompartsYear;
begin
   SQLStatement := TDateFromparts.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.DateAdd(const DateAddtype: TDatePartType; const Number: Integer; const Date: TBaseField): IDateTimeStatement;
begin
   Result := DateAdd(DateAddtype).Number(Number).Date(Date);
end;

function TQueryFieldBuilder.DateAdd(const DateAddtype: TDatePartType): IDateAddNumber;
begin
   SQLStatement := TDateAdd.Create;
   Result := AddSQLDatePiece(DateAddtype);
end;

function TQueryFieldBuilder.Vandaag: IDateStatement;
begin
   Result := DateOnly(NewSub.Nu);
end;

function TQueryFieldBuilder.Morgen: IDateStatement;
begin
   Result := DateAdd(ddDag).Number(1).Date(NewSub.Vandaag).AsDate;
end;

function TQueryFieldBuilder.Nu: IDateTimeStatement;
begin
   Result := Self;
   SQLStatement := TNu.Create;
end;

function TQueryFieldBuilder.Over1Dag: IDateTimeStatement;
begin
   Result := DateAdd(ddDag).Number(1).Date(NewSub.Nu);
end;

function TQueryFieldBuilder.DatePart(const DatepartType: TDatePartType; const aValue: TDateTime): IIntegerStatement;
begin
   SQLStatement := TDatepart.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DatePart(const DatepartType: TDatePartType; const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TDatepart.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DatePart(const DatepartType: TDatePartType; const aSubStatement: IStatement): IIntegerStatement;
begin
   SQLStatement := TDatepart.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.DateName(const DatepartType: TDatePartType; const aValue: TDateTime): IStringStatement;
begin
   SQLStatement := TDateName.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DateName(const DatepartType: TDatePartType; const aField: TBaseField): IStringStatement;
begin
   SQLStatement := TDateName.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DateName(const DatepartType: TDatePartType; const aSubStatement: IStatement): IStringStatement;
begin
   SQLStatement := TDateName.Create;
   AddSQLDatePiece(DatepartType);
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Day(const aValue: TDateTime): IIntegerStatement;
begin
   SQLStatement := TDay.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Day(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TDay.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Day(const aSubStatement: IStatement): IIntegerStatement;
begin
   SQLStatement := TDay.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Month(const aValue: TDateTime): IIntegerStatement;
begin
   SQLStatement := TMonth.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Month(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TMonth.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Month(const aSubStatement: IStatement): IIntegerStatement;
begin
   SQLStatement := TMonth.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Year(const aValue: TDateTime): IIntegerStatement;
begin
   SQLStatement := TYear.Create;
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Year(const aField: TBaseField): IIntegerStatement;
begin
   SQLStatement := TYear.Create;
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Year(const aSubStatement: IStatement): IIntegerStatement;
begin
   SQLStatement := TYear.Create;
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.OpenBracket: ICustomSQLType;
begin
   Result := AddSQLPiece(sqOpenBracket);
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
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CompareValue(const aValue: Variant): ICondition;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CompareStatement(const aSubStatement: IStatementBase): ICondition;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { IConditionCompareToMulti }
function TQueryFieldBuilder.Values(const aValues: array of Variant): IConditionCompareToMultiNext;
var i: Integer;
begin
   for i := 0 to System.Length(aValues)-1 do
      Result := AddValue(aValues[i]);
end;

function TQueryFieldBuilder.Values(const aValues: array of string): IConditionCompareToMultiNext;
var i: Integer;
begin
   for i := 0 to System.Length(aValues)-1 do
      Result := AddValue(aValues[i]);
end;

function TQueryFieldBuilder.Values(const aValues: array of Integer): IConditionCompareToMultiNext;
var i: Integer;
begin
   for i := 0 to System.Length(aValues)-1 do
      Result := AddValue(aValues[i]);
end;

function TQueryFieldBuilder.InSetField(const aField: TBaseField): IConditionCompareToMultiNext;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.InSetStatement(const aSubStatement: IStatementBase): IConditionCompareToMultiNext;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { IStatementBase }
function TQueryFieldBuilder.Plus: ICustomSQLType;
begin
   Result := AddSQLPiece(sqPlus);
end;

function TQueryFieldBuilder.CloseBracketStatement: IStatement;
begin
   Result := AddSQLPiece(sqCloseBracket);
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
   Result := AddSQLPiece(sqMin);
end;

function TQueryFieldBuilder.Keer: ICustomSQLType;
begin
   Result := AddSQLPiece(sqKeer);
end;

function TQueryFieldBuilder.DelenDoor: ICustomSQLType;
begin
   Result := AddSQLPiece(sqDelendoor);
end;

function TQueryFieldBuilder.Modulo: ICustomSQLType;
begin
   Result := AddSQLPiece(sqModulo);
end;

      { ICondition }
function TQueryFieldBuilder.Or_: IConditionCompare;
begin
   Result := AddSQLPiece(sqOr);
end;

function TQueryFieldBuilder.And_: IConditionCompare;
begin
   Result := AddSQLPiece(sqAnd);
end;

function TQueryFieldBuilder.CloseBracket: ICondition;
begin
   Result := AddSQLPiece(sqCloseBracket);
end;

      { ICaseEnd }
function TQueryFieldBuilder.CaseEnd: IStatement;
begin
   Result := Self;
end;

      { IElseCondition }
function TQueryFieldBuilder.CaseEnd(const aValue: Variant): IStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CaseEnd(const aField: TBaseField): IStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CaseEnd(const aSubStatement: IStatementBase): IStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { ICoalesceNext }
function TQueryFieldBuilder.NextCoalesce(const aValue: Variant): ICoalesceEnd;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.NextCoalesce(const aField: TBaseField): ICoalesceEnd;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NextCoalesce(const aSubStatement: IStatementBase): ICoalesceEnd;
begin
   Result := AddSubStatement(aSubStatement);
end;

      { CoalesceEnd }
function TQueryFieldBuilder.CoalesceEnd: IStatement;
begin
   Result := Self;
end;

{ IDateDiffFirstDate }
function TQueryFieldBuilder.FirstDate(const aValue: Variant): IDateDiffSecondDate;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.FirstDate(const aField: TBaseField): IDateDiffSecondDate;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.FirstDate(const aSubStatement: IDateTimeStatement): IDateDiffSecondDate;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateDiffSecondDate }
function TQueryFieldBuilder.SecondDate(const aValue: Variant): IIntegerStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.SecondDate(const aField: TBaseField): IIntegerStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.SecondDate(const aSubStatement: IDateTimeStatement): IIntegerStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateAddNumber }
function TQueryFieldBuilder.Number(const aValue: Variant): IDate;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Number(const aField: TBaseField): IDate;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Number(const aSubStatement: IIntegerStatement): IDate;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateAddDate }
function TQueryFieldBuilder.Date(const aValue: Variant): IDateTimeStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Date(const aField: TBaseField): IDateTimeStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Date(const aSubStatement: IDateTimeStatement): IDateTimeStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

function TQueryFieldBuilder.Precision(const aValue: Variant): IFloatStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.Precision(const aField: TBaseField): IFloatStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.Precision(const aSubStatement: IIntegerStatement): IFloatStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IReplace }
function TQueryFieldBuilder.OldPattern(const aValue: Variant): IReplaceNext;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.OldPattern(const aField: TBaseField): IReplaceNext;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.OldPattern(const aSubStatement: IStringStatement): IReplaceNext;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IReplaceNext }
function TQueryFieldBuilder.NewPattern(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.NewPattern(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NewPattern(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ INumberOfChars }
function TQueryFieldBuilder.NumberOfChars(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.NumberOfChars(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NumberOfChars(const aSubStatement: IIntegerStatement): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IConcatNext }
function TQueryFieldBuilder.NextConcat(const aValue: Variant): IConcatEnd;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.NextConcat(const aField: TBaseField): IConcatEnd;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.NextConcat(const aSubStatement: IStatementBase): IConcatEnd;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IConcatEnd }
function TQueryFieldBuilder.ConcatEnd: IStatement;
begin
   Result := Self;
end;

{ ISubStringStart }
function TQueryFieldBuilder.SubStringStart(const aValue: Variant): ISubStringLength;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.SubStringStart(const aField: TBaseField): ISubStringLength;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.SubStringStart(const aSubStatement: IStatementBase): ISubStringLength;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ ISubStringLength }
function TQueryFieldBuilder.StringLength(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.StringLength(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StringLength(const aSubStatement: IStatementBase): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IStuffStart }
function TQueryFieldBuilder.StuffStart(const aValue: Variant): IStuffNumberOfChars;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.StuffStart(const aField: TBaseField): IStuffNumberOfChars;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StuffStart(const aSubStatement: IStatementBase): IStuffNumberOfChars;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IStuffNumberOfChars }
function TQueryFieldBuilder.StuffNumberOfChars(const aValue: Variant): IStuffReplaceString;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.StuffNumberOfChars(const aField: TBaseField): IStuffReplaceString;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StuffNumberOfChars(const aSubStatement: IStatementBase): IStuffReplaceString;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IStuffReplaceString }
function TQueryFieldBuilder.StuffReplaceString(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.StuffReplaceString(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StuffReplaceString(const aSubStatement: IStatementBase): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ ICharIndex }
function TQueryFieldBuilder.SearchCharString(const aValue: Variant): ICharIndexStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.SearchCharString(const aField: TBaseField): ICharIndexStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.SearchCharString(const aSubStatement: IStringStatement): ICharIndexStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ ICharIndexStringStatement }
function TQueryFieldBuilder.CharIndexStartPos(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.CharIndexStartPos(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.CharIndexStartPos(const aSubStatement: IIntegerStatement): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IPatIndex }
function TQueryFieldBuilder.SearchString(const aValue: Variant): IStringStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.SearchString(const aField: TBaseField): IStringStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.SearchString(const aSubStatement: IStringStatement): IStringStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateFrompartsYear }
function TQueryFieldBuilder.DatePartYear(const aValue: Variant): IDateFrompartsMonth;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DatePartYear(const aField: TBaseField): IDateFrompartsMonth;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DatePartYear(const aSubStatement: IIntegerStatement): IDateFrompartsMonth;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateFrompartsMonth }
function TQueryFieldBuilder.DatePartMonth(const aValue: Variant): IDateFrompartsDay;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DatePartMonth(const aField: TBaseField): IDateFrompartsDay;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DatePartMonth(const aSubStatement: IIntegerStatement): IDateFrompartsDay;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IDateFrompartsDay }
function TQueryFieldBuilder.DatePartDay(const aValue: Variant): IDateStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.DatePartDay(const aField: TBaseField): IDateStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.DatePartDay(const aSubStatement: IIntegerStatement): IDateStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IBetweenStart }
function TQueryFieldBuilder.StartDate(const aValue: Variant): IBetweenEnd;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.StartDate(const aField: TBaseField): IBetweenEnd;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.StartDate(const aSubStatement: IDateStatement): IBetweenEnd;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IBetweenEnd }
function TQueryFieldBuilder.EndDate(const aValue: Variant): ICondition;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.EndDate(const aField: TBaseField): ICondition;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.EndDate(const aSubStatement: IDateStatement): ICondition;
begin
   Result := AddSubStatement(aSubStatement);
end;

{ IHashBytes }
function TQueryFieldBuilder.HashBytesInput(const aValue: Variant): IBinaryStatement;
begin
   Result := AddValue(aValue);
end;

function TQueryFieldBuilder.HashBytesInput(const aField: TBaseField): IBinaryStatement;
begin
   Result := AddField(aField);
end;

function TQueryFieldBuilder.HashBytesInput(const aSubStatement: IStatementBase): IBinaryStatement;
begin
   Result := AddSubStatement(aSubStatement);
end;
{$ENDREGION}

{$REGION 'Implementation of CustomSQLFields'}
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

function TCustomSQLField.GetCustomSQL(const aQuery: IQueryDetails; const dbConType: TDBConnectionType; var aParams: TVariantArray; const WithAlias: Boolean): string;
var GenerateParams: RGenerateSQLParams;
begin
   GenerateParams := RGenerateSQLParams.Create(aQuery, dbConType, aParams, WithAlias, Self);
   Result := CustomSQL.GetCustomSQL(GenerateParams);
   aParams := GenerateParams.aParams; // toegevoegde params ook weer teruggeven
end;

function TCustomSQLField.GetRequiredFields: TFieldArray;
begin
   SetLength(Result, 0);
   (FCustomSQLBuilder as TQueryFieldBuilder).AddRequiredFields(Result);
end;

{ TCustomSQLStringField }

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
   Result := ftFieldDouble;
end;

{ TSQLCurrencyField }

function TSQLCurrencyField.GetFieldType: TFieldType;
begin
   Result := ftFieldCurrency;
end;

{ TSQLPercentageField }

procedure TSQLPercentageField.SetPercentageSQL(const Field1, Field2: TBaseField);
begin
// case when Field2 <> 0 then Field1 / Field2 end
   with CustomSQL do
      New.CaseWhen(NewSub.FieldCompare(Field2).NotEqual.CompareValue(0))
         .ThenEnd(NewSub.FieldAsStatement(Field1, True).AsFloat.DelenDoor.FieldAsStatement(Field2));
end;

{ TSQLDateTimeFieldBase }

function TSQLDateTimeFieldBase.GetFieldType: TFieldType;
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
{$ENDREGION}
{ TCustomSQLVelden }

procedure TDatabaseSQLVelden.AfterConstruction;
begin
   inherited;

   SQL_Now_Field.CustomSQL          .New.Nu;
   SQL_TodayField.CustomSQL         .New.ConvertTo(csDateTime, SQL_TodayField.CustomSQL.NewSub.Vandaag); // weer terug naar datetime anders snapt ado er geen bal meer van
   SQL_Now_Plus_1_Field.CustomSQL   .New.Over1Dag;
   SQL_Today_Plus_1Field.CustomSQL  .New.Morgen;
   Dummy.CustomSQL                  .New.VariantAsStatement(1);
end;

function TDatabaseSQLVelden.GetSQLDateField(Index: Integer): TSQLDateField;
begin
   Result := Items[Index] as TSQLDateField;
end;

function TDatabaseSQLVelden.GetSQLDateTimeField(index: Integer): TSQLDateTimeField;
begin
   Result := Items[Index] as TSQLDateTimeField;
end;

function TDatabaseSQLVelden.GetSQLIntegerField(index: Integer): TSQLIntegerField;
begin
   Result := Items[Index] as TSQLIntegerField;
end;

{$REGION 'implementation of param types'}
{ RGenerateSQLParams }

constructor RGenerateSQLParams.Create(const aQuery: IQueryDetails; const adbConType: TDBConnectionType; aParams: TVariantArray; const aWithAlias: Boolean; const aField: TBaseField);
begin
   FQuery := aQuery;
   FdbConType := adbConType;
   FWithAlias := aWithAlias;
   FField := aField;
   Self.aParams := aParams;
   FFieldInGroupByState:= bUnknown;
end;

{ TQueryFieldBuilder.SQLParameter }

constructor TQueryFieldBuilder.TSQLParameter.Create;
begin
   inherited;
   Value := null;
   Field := nil;
   Statement := nil;
   Builder := nil;
end;

constructor TQueryFieldBuilder.TSQLParameter.Create(const aValue: Variant);
begin
   Create;
   Value := aValue;
end;

constructor TQueryFieldBuilder.TSQLParameter.Create(const aValue: TBaseField);
begin
   Create;
   Field := aValue;
end;

constructor TQueryFieldBuilder.TSQLParameter.Create(const aValue: TSQLStatement);
begin
   Create;
   Statement := aValue;
end;

constructor TQueryFieldBuilder.TSQLParameter.Create(const aValue: TQueryFieldBuilder);
begin
   Create;
   Builder := aValue;
   Statement := aValue.SQLStatement;
end;

destructor TQueryFieldBuilder.TSQLParameter.Destroy;
begin
   if Assigned(Builder) then
   begin
      Dec(Builder.FRefCount);
      if (Builder.FRefCount = 0) then
         Builder.Free;
   end
   else
      Statement.Free; // statement wordt dan door builder wel opgeruimd
   inherited;
end;

procedure TQueryFieldBuilder.TSQLParameter.AddRequiredFields(var Fields: TFieldArray);
begin
   if Assigned(Field) then
      AddFieldToArray(Field, Fields, True)
   else if Assigned(Statement) then
      Statement.AddRequiredFields(Fields);
end;

function TQueryFieldBuilder.TSQLParameter.StatementIsOfClass(const aClass: TSQLStatementClass): Boolean;
begin
   if Assigned(Statement) then
      Result := (Statement is aClass)
   else
      Result := False;
end;

function TQueryFieldBuilder.TSQLParameter.ToSQL(var GenerateParams: RGenerateSQLParams): string;
   function FieldIsInGroupBy(const CheckField: TBaseField): Boolean;
   var GroupByField, SubField: TBaseField;
   begin
      with GenerateParams do
      begin
         case FFieldInGroupByState of
            bTrue: Exit(True);
            bFalse: Exit(False);
         end;

         Result := False;
         try
            if (not Assigned(Query.GroupByPart)) then
               Exit(False);

            for GroupByField in Query.GroupByPart.FGroupBySet do
            begin
               if (GroupByField = CheckField) then
                  Exit(True)
               else if (GroupByField is TCustomSQLField) then
               begin
                  for SubField in (GroupByField as TCustomSQLField).GetRequiredFields do
                  begin
                     Result := FieldIsInGroupBy(SubField);
                     if Result then
                        Exit;
                  end;
               end;
            end;
         finally
            if Result then
               FFieldInGroupByState := bTrue
            else
               FFieldInGroupByState := bFalse;
         end;
      end;
   end;

begin
   with GenerateParams do
   begin
      if Assigned(Field) then
         Result := TSQLBuilder.GetFieldSQLWithAlias(Query, Field, dbConType, aParams, WithAlias)
      else if Assigned(Statement) then
         Result := Statement.ToSQL(GenerateParams)
      else
      begin
         if FieldIsInGroupBy(GenerateField) then // als veld in group by, dan geen parameters gebruiken (dan is veld ongelijk aan veld in select aan geeft dit query error)
            Result := VariantToSQLString(Value)
         else
         begin
            Result := '?';
            SetLength(aParams, System.Length(aParams) + 1);
            aParams[High(aParams)] := Value;
         end;
      end;
   end;
end;

{ TQueryFieldBuilder.TSQLStatement }

procedure TQueryFieldBuilder.TSQLStatement.AddParam(const Value: TSQLParameter);
begin
   Params.Add(Value);
end;

procedure TQueryFieldBuilder.TSQLStatement.AddRequiredFields(var Fields: TFieldArray);
var i: Integer;
begin
   for i := 0 to ParameterCount-1 do
      Parameter[i].AddRequiredFields(Fields);
end;

constructor TQueryFieldBuilder.TSQLStatement.Create;
begin
   Params := TParamsList.Create;
end;

destructor TQueryFieldBuilder.TSQLStatement.Destroy;
begin
   Params.Free;
   inherited;
end;

function TQueryFieldBuilder.TSQLStatement.GetParam(const Index: Integer): TSQLParameter;
begin
   Assert(Index < Params.Count);
   Result := Params[Index];
end;

function TQueryFieldBuilder.TSQLStatement.FirstSQLPieceIndex: Integer;
var i: Integer;
begin
   for i := 0 to ParameterCount-1 do
   begin
      if Parameter[i].StatementIsOfClass(TSQLPiece) then
         Exit(Math.Max(i-1,0));
   end;
   Result := ParameterCount-1;
end;

function TQueryFieldBuilder.TSQLStatement.ParameterCount: Integer;
begin
   Result := Params.Count;
end;

function TQueryFieldBuilder.TSQLStatement.ParamsToSQL(const VanafIndex: Integer; var GenerateParams: RGenerateSQLParams): string;
var i: Integer;
begin
   Result := '';
   for i := VanafIndex to ParameterCount-1 do
      Result := Result + Parameter[i].ToSQL(GenerateParams);
end;

{ TQueryFieldBuilder.TSQLFunction }

constructor TQueryFieldBuilder.TSQLFunction.Create;
begin
   inherited Create;
   FDistinct := False;
end;

function TQueryFieldBuilder.TSQLFunction.ToSQL(var GenerateParams: RGenerateSQLParams): string;
var i, Max: Integer;
begin
   Result := Format('%s(%s%s',
      [SQLFunctionName(GenerateParams.dbConType),
      ifthen(FDistinct, 'distinct '),
      Parameter[0].ToSQL(GenerateParams)]);
   Max := FirstSQLPieceIndex;// max is laatste deel van de functie
   for i := 1 to Max do
      Result := Result + ','+Parameter[i].ToSQL(GenerateParams);;
   Result := Result +')'+ParamsToSQL(Max+1, GenerateParams);
end;

{ TQueryFieldBuilder.TSQLDistinctFunction }

constructor TQueryFieldBuilder.TSQLDistinctFunction.Create(const Distinct: Boolean);
begin
   inherited Create;
   FDistinct := Distinct;
end;

{ TQueryFieldBuilder.TSQLParamterOnlyStatement }

function TQueryFieldBuilder.TSQLParamterOnlyStatement.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   Result := ParamsToSQL(0, GenerateParams);
end;

{ TQueryFieldBuilder.TAlleenCijfers }

function TQueryFieldBuilder.TAlleenCijfers.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'dbo.AlleenCijfers';
end;

{ TQueryFieldBuilder.TLeftTrimmedStatement }

function TQueryFieldBuilder.TLeftTrimmedStatement.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'LTrim';
end;

{ TQueryFieldBuilder.TRightTrimmedStatement }

function TQueryFieldBuilder.TRightTrimmedStatement.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'RTrim';
end;

{ TQueryFieldBuilder.TMin }

function TQueryFieldBuilder.TMin.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Min';
end;

{ TQueryFieldBuilder.TMax }

function TQueryFieldBuilder.TMax.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Max';
end;

{ TQueryFieldBuilder.TCount }

function TQueryFieldBuilder.TCount.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Count';
end;

{ TQueryFieldBuilder.TAbs }

function TQueryFieldBuilder.TAbs.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Abs';
end;

{ TQueryFieldBuilder.TSum }

function TQueryFieldBuilder.TSum.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Sum';
end;

{ TQueryFieldBuilder.TDay }

function TQueryFieldBuilder.TDay.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Day';
end;

{ TQueryFieldBuilder.TMonth }

function TQueryFieldBuilder.TMonth.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Month';
end;

{ TQueryFieldBuilder.TYear }

function TQueryFieldBuilder.TYear.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Year';
end;

{ TQueryFieldBuilder.TUpper }

function TQueryFieldBuilder.TUpper.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Upper';
end;

{ TQueryFieldBuilder.TLower }

function TQueryFieldBuilder.TLower.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Lower';
end;

{ TQueryFieldBuilder.TRound }

function TQueryFieldBuilder.TRound.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Round';
end;

{ TQueryFieldBuilder.TIsNullStatement }

function TQueryFieldBuilder.TIsNullStatement.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   case dbConType of
      dbtMYSQL:
         Result := 'IfNull';
   else
         Result := 'IsNull';
   end;
end;

{ TQueryFieldBuilder.TNullIf }

function TQueryFieldBuilder.TNullIf.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'NullIf';
end;

{ TQueryFieldBuilder.TLeft }

function TQueryFieldBuilder.TLeft.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Left';
end;

{ TQueryFieldBuilder.TRight }

function TQueryFieldBuilder.TRight.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Right';
end;

{ TQueryFieldBuilder.TAverage }

function TQueryFieldBuilder.TAverage.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Avg';
end;

{ TQueryFieldBuilder.TChecksum }

function TQueryFieldBuilder.TChecksum.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Checksum';
end;

{ TQueryFieldBuilder.TStandardDeviation }

function TQueryFieldBuilder.TStandardDeviation.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'StDev';
end;

{ TQueryFieldBuilder.TStandardDeviationPopulation }

function TQueryFieldBuilder.TStandardDeviationPopulation.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'StDevP';
end;

{ TQueryFieldBuilder.THashBytes }

function TQueryFieldBuilder.THashBytes.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'HashBytes';
end;

{ TQueryFieldBuilder.TReplicate }

function TQueryFieldBuilder.TReplicate.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   case dbConType of
      dbtMYSQL:
         Result := 'Repeat';
   else
         Result := 'Replicate';
   end;
end;

{ TQueryFieldBuilder.TVariation }

function TQueryFieldBuilder.TVariation.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Var';
end;

{ TQueryFieldBuilder.TVariationPopulation }

function TQueryFieldBuilder.TVariationPopulation.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'VarP';
end;

{ TQueryFieldBuilder.TReverse }

function TQueryFieldBuilder.TReverse.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Reverse';
end;

{ TQueryFieldBuilder.TFloor }

function TQueryFieldBuilder.TFloor.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Floor';
end;

{ TQueryFieldBuilder.TCeiling }

function TQueryFieldBuilder.TCeiling.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Ceiling';
end;

{ TQueryFieldBuilder.TLength }

function TQueryFieldBuilder.TLength.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   case dbConType of
      dbtMYSQL:   Result := 'Char_Length';
   else
                  Result := 'Len';
   end;
end;

{ TQueryFieldBuilder.TCoalesce }

function TQueryFieldBuilder.TCoalesce.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Coalesce';
end;

{ TQueryFieldBuilder.TConcat }

function TQueryFieldBuilder.TConcat.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Concat';
end;

{ TQueryFieldBuilder.TReplace }

function TQueryFieldBuilder.TReplace.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Replace';
end;

{ TQueryFieldBuilder.TDateDiff }

function TQueryFieldBuilder.TDateDiff.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'DateDiff';
end;

{ TQueryFieldBuilder.TDateAdd }

function TQueryFieldBuilder.TDateAdd.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'DateAdd';
end;

{ TQueryFieldBuilder.TDaypart }

function TQueryFieldBuilder.TDatepart.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Datepart';
end;

{ TQueryFieldBuilder.TDateName }

function TQueryFieldBuilder.TDateName.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'DateName';
end;

{ TQueryFieldBuilder.TDateFromparts }

function TQueryFieldBuilder.TDateFromparts.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'DateFromparts';
end;

{ TQueryFieldBuilder.TSubstring }

function TQueryFieldBuilder.TSubstring.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Substring';
end;

{ TQueryFieldBuilder.TStuff }

function TQueryFieldBuilder.TStuff.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'Stuff';
end;

{ TQueryFieldBuilder.TCharIndex }

function TQueryFieldBuilder.TCharIndex.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   case dbConType of
      dbtMYSQL:
         Result := 'Locate';
   else
         Result := 'CharIndex';
   end;
end;

{ TQueryFieldBuilder.TPatIndex }

function TQueryFieldBuilder.TPatIndex.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'PatIndex';
end;

{ TQueryFieldBuilder.TBinaryTohexStr }

function TQueryFieldBuilder.TBinaryTohexStr.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := 'master.dbo.fn_varbintohexstr';
end;

{ TQueryFieldBuilder.TValuesSet }

function TQueryFieldBuilder.TValuesSet.SQLFunctionName(const dbConType: TDBConnectionType): string;
begin
   Result := '';
end;

{ TQueryFieldBuilder.TConvert }

constructor TQueryFieldBuilder.TConvert.Create(const aType: TConvertSQLType; const aStringSize: Integer);
begin
   inherited Create;
   FType := aType;
   FStringSize := aStringSize;
end;

function TQueryFieldBuilder.TConvert.ToSQL(var GenerateParams: RGenerateSQLParams): string;
var TypeStr: string;
begin
   case FType of
      csDate:        TypeStr := 'Date';
      csDateTime:    TypeStr := 'Datetime';
      csString:
      begin
         if (FStringSize = 0) then
                     TypeStr :=  'Varchar'
         else
                     TypeStr := Format('Varchar(%d)',[FStringSize]);
      end;
      csBit:         TypeStr := 'Bit';
      csFloat:       TypeStr := 'Float';
      csInt:         TypeStr := 'Int';
   else
      Assert(False);
   end;
   case GenerateParams.dbConType of
      dbtMYSQL:
      Result := Format('Convert(%s,%s)%s', // CONVERT('2014-02-28 08:14:57', DATETIME)
         [Parameter[0].ToSQL(GenerateParams),
         TypeStr,
         ParamsToSQL(1,GenerateParams)]);
   else
      Result := Format('Convert(%s,%s)%s', //  CONVERT(DATETIME, '2014-02-28 08:14:57')
         [TypeStr,
         Parameter[0].ToSQL(GenerateParams),
         ParamsToSQL(1,GenerateParams)]);
   end;
end;

{ TQueryFieldBuilder.TNu }

function TQueryFieldBuilder.TNu.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   case GenerateParams.dbConType of
      dbtMYSQL: Result := 'Now()';
   else
                Result := 'Getdate()';
   end;
   Result := Result + ParamsToSQL(0,GenerateParams);
end;

{ TQueryFieldBuilder.TDateOnly }

function TQueryFieldBuilder.TDateOnly.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   case GenerateParams.dbConType of
      dbtMYSQL: Result := 'Date(%s)';
   else
      if (DatabaseCompatLevel >= 2008) then
         Result := 'Convert(Date,%s)'
      else
         Result := 'Dbo.DateOnly(%s)';
   end;
      Result := Format(Result+'%s',
      [Parameter[0].ToSQL(GenerateParams),
      ParamsToSQL(1,GenerateParams)]);
end;

{ TQueryFieldBuilder.TCaseOf }

function TQueryFieldBuilder.TCaseOf.ToSQL(var GenerateParams: RGenerateSQLParams): string;
// case  status when 1 then 'Nieuw' when 2 then 'Afgekeurd' else 'Geen idee' end
var i, Max: Integer;
    MetElse: Boolean;
begin
   Result := 'case '+ Parameter[0].ToSQL(GenerateParams);
   Max := FirstSQLPieceIndex;
   MetElse := Odd(FirstSQLPieceIndex);
   if MetElse then
      Max := Max -1; // 'else' niet

   for i := 1 to Max do
   begin
      if Odd(i) then
         Result := Result +' when '+Parameter[i].ToSQL(GenerateParams)
      else
         Result := Result + ' then '+Parameter[i].ToSQL(GenerateParams);
   end;
   if MetElse then
      Result := Result + ' else '+ Parameter[Max+1].ToSQL(GenerateParams);
   Result := Result + ' end';

   if MetElse then
      Max := Max + 1; // weer terug naar oude max
   Result := Result + ParamsToSQL(Max+1,GenerateParams);
end;

{ TQueryFieldBuilder.TCaseWhen }

function TQueryFieldBuilder.TCaseWhen.ToSQL(var GenerateParams: RGenerateSQLParams): string;
var RestIndex: Integer;
begin
   Result := Format('case when %s then %s',
      [Parameter[0].ToSQL(GenerateParams),
      Parameter[1].ToSQL(GenerateParams)]);
   RestIndex := FirstSQLPieceIndex;
   if (RestIndex >= 2) then
      Result := Result + ' else ' +Parameter[2].ToSQL(GenerateParams);
   Result := Result + ' end'+ParamsToSQL(RestIndex+1,GenerateParams);// rest van statement
end;

{ TQueryFieldBuilder.TBetween }

function TQueryFieldBuilder.TBetween.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   Result := Format(' between %s and %s%s',
      [Parameter[0].ToSQL(GenerateParams),
      Parameter[1].ToSQL(GenerateParams),
      ParamsToSQL(2,GenerateParams)]);
end;

{ TQueryFieldBuilder.TCustomSQLStatement }

constructor TQueryFieldBuilder.TCustomSQLStatement.Create(const aSQL: string);
begin
   inherited Create;
   FSQL := aSQL;
end;

function TQueryFieldBuilder.TCustomSQLStatement.ToSQL(var GenerateParams: RGenerateSQLParams): string;
var i: Integer;
begin
   Result := FSQL;
   for i := 0 to ParameterCount-1 do
      Result := StringReplace(Result, GetFieldTag(i), Parameter[i].ToSQL(GenerateParams),[]);
end;

{ TQueryFieldBuilder.TSQLPiece }

constructor TQueryFieldBuilder.TSQLPiece.Create(const aSQLPieceType: TSQLPieceType);
begin
   inherited Create;
   FSQLPieceType := aSQLPieceType;
end;

function TQueryFieldBuilder.TSQLPiece.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   case FSQLPieceType of
      sqGreaterOrEqualThen:   Result := '>=';
      sqGreaterThen:          Result := '>';
      sqSmallerOrEqualThen:   Result := '<=';
      sqSmallerThen:          Result := '<';
      sqEqual:                Result := '=';
      sqNotEqual:             Result := '<>';
      sqLike:                 Result := ' like ';
      sqNotLike:              Result := ' not like ';
      sqInSet:                Result := ' in ';
      sqNotInSet:             Result := ' not in ';
      sqIsNull:               Result := ' is null';
      sqIsNotNull:            Result := ' is not null';
      sqPlus:                 Result := '+';
      sqMin:                  Result := '-';
      sqKeer:                 Result := '*';
      sqDelendoor:            Result := '/';
      sqModulo:               Result := '%';
      sqOpenBracket:          Result := '(';
      sqCloseBracket:         Result := ')';
      sqOr:                   Result := ' or ';
      sqAnd:                  Result := ' and ';
      sqNot:                  Result := ' not';
   else
      Assert(False);
   end;
end;

{ TQueryFieldBuilder.TSQLDatePiece }

constructor TQueryFieldBuilder.TSQLDatePiece.Create(const aSQLDatePieceType: TDatePartType);
begin
   inherited Create;
   FSQLDatePieceType := aSQLDatePieceType
end;

function TQueryFieldBuilder.TSQLDatePiece.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   case FSQLDatePieceType of
      ddJaar:               Result := 'yy';
      ddKwartJaar:          Result := 'qq';
      ddMaand:              Result := 'mm';
      ddDagVanJaar:         Result := 'dy';
      ddDag:                Result := 'dd';
      ddWeek:               Result := 'wk';
      ddWeekdag:            Result := 'dw';
      ddUur:                Result := 'hh';
      ddMinuut:             Result := 'mi';
      ddSeconde:            Result := 'ss';
      ddMiliseconde:        Result := 'ms';
      ddMicroseconde:       Result := 'mcs';
      ddNanoseconde:        Result := 'ns';
   else
      Assert(False);
   end;
end;

{ TQueryFieldBuilder.THashBytesAlgoritm }

constructor TQueryFieldBuilder.THashBytesAlgoritm.Create(const aHashAlgoritme: THashAlgoritme);
begin
   inherited Create;
   FHashAlgoritme := aHashAlgoritme;
end;

function TQueryFieldBuilder.THashBytesAlgoritm.ToSQL(var GenerateParams: RGenerateSQLParams): string;
begin
   case FHashAlgoritme of
      haMD2:            Result := 'MD2';
      haMD4:            Result := 'MD4';
      haMD5:            Result := 'MD5';
      haSHA:            Result := 'SHA';
      haSHA1:           Result := 'SHA1';
      haSHA2_256:       Result := 'SHA2_256';
      haSHA2_512:       Result := 'SHA2_512';
   else
      Assert(False);
   end;
   Result := QuotedStr(Result)
end;

{$ENDREGION}
{$ENDREGION}

initialization
   GDatabaseSQLVelden := TDatabaseSQLVelden.Create(nil);

finalization
   GDatabaseSQLVelden.Free;


end.
