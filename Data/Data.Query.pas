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
unit Data.Query;

interface

uses
  Generics.Collections,
  Data.DataRecord;

type
  TQueryBuilder  = class;

  TWherePart         = class;
  TWherePartList     = class;
  TJoinPart          = class;
  TJoinPartList      = class;
  TOrderByPartList   = class;
  TGroupByPart       = class;

  TInsertFieldValues = class;
  TUpdateFieldValues = class;
  TInsertFieldFields = class;
  TUpdateFieldFields = class;

  ISelect = interface;
  ISelectNext = interface;
  IUpdate = interface;
  IUpdateEnd = interface;
  IDelete = interface;
  IInsert = interface;
  IHaving = interface;
  IQueryDetails = interface;

  IQueryBuilder = interface
    ['{72A1B9FC-4642-4624-B708-1C23BC90DDC5}']
    function Select: ISelect;
    function CurrentSelect: ISelectNext;
    function CurrentInsert: IInsert;
    function CurrentUpdate: IUpdateEnd;
    function Update: IUpdate;
    function Delete: IDelete;
    function Insert: IInsert;
    function Details: IQueryDetails;
  end;

  TQueryType = (qtNone, qtSelect, qtUpdate, qtDelete, qtInsert);

  //http://msdn.microsoft.com/en-us/library/ms187373.aspx
  TTableHint = (
          KEEPIDENTITY,
          KEEPDEFAULTS,
          FASTFIRSTROW,
          HOLDLOCK,
          IGNORE_CONSTRAINTS,
          IGNORE_TRIGGERS,
          NOWAIT,
          NOLOCK,
          PAGLOCK,
          READCOMMITTED,
          READCOMMITTEDLOCK,
          READPAST,
          REPEATABLEREAD,
          ROWLOCK,
          SERIALIZABLE,
          TABLOCK,
          TABLOCKX,
          UPDLOCK,
          XLOCK
          );
  TTableHints = set of TTableHint;

  TSelectOperation = (soSelect, soSum, soMin, soMax, soAvg, soCount, soCountDistinct);
  TSelectFields = class(TDictionary<TBaseField, TSelectOperation>);

  IQueryDetails = interface
    ['{00A8B1B4-E88C-4935-BAFF-CD51D61FB8B5}']
    function QueryType   : TQueryType;

    //function Database: string;
    function Table: string;
    function MainTableField: TBaseField;
    function FromSubQuery: IQueryDetails;

    procedure SetParentQuery(aParent: IQueryDetails);  //in case of subqueries
    function AliasCount: Integer;
    function GetAliasForField(aField: TBaseField): string;

    function DoTopCount: Integer;
    function DoDistinct: Boolean;
    function TableHints: TTableHints;

    function SelectFields: TSelectFields;
    function SelectFields_Ordered: TFieldList;
    function SelectFieldsSubqueries: TList<IQueryDetails>;
    //
    function WhereParts: TWherePartList;
    function HavingParts: TWherePartList;
    //
    function JoinParts : TJoinPartList;
    //
    function OrderByParts: TOrderByPartList;
    function GroupByPart: TGroupByPart;
    //function TempJoin: string;

    function InsertFromRecord: TDataRecord;
    function InsertFieldValues: TInsertFieldValues;
    function InsertFieldFields: TInsertFieldFields;
    function RetrieveIdentityAfterInsert: Boolean;
    function ActivateIdentityInsert: Boolean;

    function UpdateFieldValues: TUpdateFieldValues;
    function UpdateIncFieldValues: TUpdateFieldValues;
    function UpdateFieldFields: TUpdateFieldFields;
    function UpdateIncFieldFields: TUpdateFieldFields;
  end;

  IWhereDetails = interface
     ['{A1D93999-F52A-409B-8515-2518950710E7}']
     function WhereParts: TWherePartList;
  end;


  IJoin = interface;
  IJoinNext = interface;
  IWhere = interface;
  IWhereNext = interface;
  IWhereEnd = interface;
  IWhere_Standalone = interface;
  IGroupingNext = interface;
  IOrdering = interface;
  IHavingNext = interface;
  IHavingEnd = interface;

  ISelect = interface
    function TopCount(aRecordCount: Integer): ISelect;
    function Distinct: ISelect;
    function AllFieldsOf  (aFields: TDataRecord        )  : ISelectNext;
    function Fields       (aFields: array of TBaseField)  : ISelectNext;
    function Sum          (aField: TBaseField)            : ISelectNext;
    function Count        (aField: TBaseField)            : ISelectNext;
    function CountDistinct(aField: TBaseField)            : ISelectNext;
    function Average      (aField: TBaseField)            : ISelectNext;
    function Min          (aField: TBaseField)            : ISelectNext;
    function Max          (aField: TBaseField; const aResultField: TBaseField = nil): ISelectNext;
    function SubQueryField(aSubQuery: IQueryBuilder)      : ISelectNext;
  end;

  ISelectNext = interface(ISelect)
    ['{A2D21D0C-0F9A-4880-9A7B-0C1CF3255D77}']
    function Select: ISelect;
    function FromSubQuery(aSubQuery: IQueryBuilder): ISelectNext;

    {join}
    function InnerJoin     : IJoin;
    function RightOuterJoin: IJoin;
    function LeftOuterJoin : IJoin;

    {where}
    function Where   : IWhere;
    function AndWhere: IWhere; overload;
    function AndWhere(aWhereObject: IWhere_Standalone): IWhere; overload;
    function OrWhere : IWhere; overload;
    function OrWhere(aWhereObject: IWhere_Standalone): IWhere; overload;

    {grouping}
    function GroupBy(const aFields: array of TBaseField): IGroupingNext;

    {ordering}
    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;

    function WithTableHints(aHints: TTableHints): ISelectNext;
    function AsQuery: IQueryBuilder;
  end;

  IWhere = interface
    function FieldValue(aField: TBaseField): IWhereNext;
//    function IsNull    (aField: TBaseField): IWhereEnd;

    function Exists   (const aSubQuery: IQueryBuilder): IWhereEnd;
    function NotExists(const aSubQuery: IQueryBuilder): IWhereEnd;

    function DateBetween(const BeginField, EindField: TBaseField; Datum: TDateTime): IWhereEnd; overload;
    function DateBetween(const BeginField, EindField, DatumField: TBaseField): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IWhereEnd; overload;

    function OpenBracket  : IWhere;     // (
    function CloseBracket : IWhereEnd;  // )
    function AndWhere     : IWhere;
    function OrWhere      : IWhere;
  end;

  IWhereNext  = interface
    function ISValue       (const aValue: Variant): IWhereEnd;
    function ISNotValue    (const aValue: Variant): IWhereEnd;
    function Equal         (const aValue: Variant         ): IWhereEnd; overload;
    function Equal         (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function EqualOrNull   (const aValue: Variant         ): IWhereEnd; overload;
    function NotEqual      (const aValue: Variant         ): IWhereEnd; overload;
    function NotEqual      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function GreaterThan   (const aValue: Variant         ): IWhereEnd; overload;
    function GreaterThan   (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function GreaterOrEqual(const aValue: Variant         ): IWhereEnd; overload;
    function GreaterOrEqual(const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function LessThan      (const aValue: Variant         ): IWhereEnd; overload;
    function LessThan      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function LessOrEqual   (const aValue: Variant         ): IWhereEnd; overload;
    function LessOrEqual   (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function Like          (const aValue: string        ) : IWhereEnd;
    function NotLike       (const aValue: string        ) : IWhereEnd;
    function InSet         (const aSet: array of Variant): IWhereEnd; overload;
    function InSet         (const aSet: array of Integer): IWhereEnd; overload;
    function InSet         (const aSet: array of string): IWhereEnd; overload;
    function InSet         (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function NotInSet      (const aSet: array of Variant): IWhereEnd; overload;
    function NotInSet         (const aSet: array of Integer): IWhereEnd; overload;
    function NotInSet         (const aSet: array of string): IWhereEnd; overload;
    function NotInSet      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function EqualField             (const aField: TBaseField): IWhereEnd;
    function NotEqualField          (const aField: TBaseField): IWhereEnd;
    function GreaterThanField       (const aField: TBaseField): IWhereEnd;
    function GreaterOrEqualField    (const aField: TBaseField): IWhereEnd;
    function LessThanField          (const aField: TBaseField): IWhereEnd;
    function LessOrEqualField       (const aField: TBaseField): IWhereEnd;
    function IsNull        ()                  : IWhereEnd;
    function IsNotNull     ()                  : IWhereEnd;

  end;

  IWhereEnd = interface(IWhere)
    function AsQuery: IQueryBuilder;

    {grouping}
    function GroupBy(const aFields: array of TBaseField): IGroupingNext;

    {ordering}
    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;
  end;

  IWhereNext_Standalone = interface;
  IWhere_Standalone = interface
    function FieldValue(aField: TBaseField): IWhereNext_Standalone;
//    function IsNull    (aField: TBaseField): IWhere_Standalone;

    function Exists   (const aSubQuery: IQueryBuilder): IWhere_Standalone;
    function NotExists(const aSubQuery: IQueryBuilder): IWhere_Standalone;

    function OpenBracket  : IWhere_Standalone;     // (
    function CloseBracket : IWhere_Standalone;  // )
    function AndWhere     : IWhere_Standalone;
    function OrWhere      : IWhere_Standalone;
  end;

  IWhereNext_Standalone = interface
    function ISValue       (const aValue: Variant): IWhere_Standalone;
    function ISNotValue    (const aValue: Variant): IWhere_Standalone;
    function Equal         (const aValue: Variant): IWhere_Standalone;
    function NotEqual      (const aValue: Variant): IWhere_Standalone;
    function GreaterThan   (const aValue: Variant): IWhere_Standalone;
    function GreaterOrEqual(const aValue: Variant): IWhere_Standalone;
    function LessThan      (const aValue: Variant): IWhere_Standalone;
    function LessOrEqual   (const aValue: Variant): IWhere_Standalone;
    function Like          (const aValue: string) : IWhere_Standalone;
    function NotLike       (const aValue: string) : IWhere_Standalone;
    function InSet         (const aSet: array of Variant): IWhere_Standalone; overload;
    function InSet         (const aSet: array of Integer): IWhere_Standalone; overload;
    function InSet         (const aSet: array of string): IWhere_Standalone; overload;
    function InSet         (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function NotInSet      (const aSet: array of Variant): IWhere_Standalone; overload;
    function NotInSet         (const aSet: array of Integer): IWhere_Standalone; overload;
    function NotInSet         (const aSet: array of string): IWhere_Standalone; overload;
    function NotInSet      (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;

    function EqualField             (const aField: TBaseField): IWhere_Standalone;
    function NotEqualField          (const aField: TBaseField): IWhere_Standalone;
    function GreaterThanField       (const aField: TBaseField): IWhere_Standalone;
    function GreaterOrEqualField    (const aField: TBaseField): IWhere_Standalone;
    function LessThanField          (const aField: TBaseField): IWhere_Standalone;
    function LessOrEqualField       (const aField: TBaseField): IWhere_Standalone;
    function IsNull    (): IWhere_Standalone;
    function IsNotNull (): IWhere_Standalone;
  end;

  TJoinCompare   = (jcEqual, jcNotEqual, jcIs, jcIsNot, jcGreater, jcGreaterEqual,
                    jcLess, jcLessEqual, jcLike, jcInSet, jcNotInSet, jcEqualField, jcNotEqualField,
                    jcGreaterField, jcGreaterEqualField, jcLessField, jcLessEqualField);

  IJoin = interface
    ['{C64FCE93-3F79-43BA-85AC-036046DC5A9E}']
    /// <summary>Define the fields to join.</summary>
    ///   <param name="aJoinTableField"> A field of the new table to join. </param>
    ///   <param name="aValueTableField"> A field of the source table to join on </param>
    ///   <comments>First field is of the new table to join. Second is the field of the source table.</comments>
    function OnFields          (aJoinTableField, aValueTableField: TBaseField): IJoinNext;
    function OnFieldAndValue   (aJoinTableField: TBaseField; const aValue: Variant) : IJoinNext;
    function OnFieldAndNotValue(aJoinTableField: TBaseField; const aValue: Variant) : IJoinNext;
    function OnFieldInSet      (aJoinTableField: TBaseField; const aValues: array of Variant): IJoinNext;
    function OnFieldCompare    (aJoinTableField: TBaseField; aCompare: TJoinCompare; const aValue: Variant): IJoinNext; overload;
    function OnFieldCompare    (aJoinTableField: TBaseField; aCompare: TJoinCompare; const aCompareField: TBaseFIeld): IJoinNext; overload;

    function SubQuery(aSubQuery: IQueryBuilder): IJoin;

    function OpenJoinBracket : IJoin;   // (
    function CloseJoinBracket: IJoin;   // )
  end;

  IJoinNext = interface(ISelectNext)
    function AndJoin: IJoin;
    function OrJoin : IJoin;
    function CloseJoinBracketN: IJoinNext;   // )

    function WithJoinTableHints(aHints: TTableHints): IJoinNext;
  end;

  IGrouping = interface
    function AsQuery: IQueryBuilder;

    function GroupBy(const aFields: array of TBaseField): IGroupingNext;
  end;

  IGroupingNext = interface(IGrouping)
    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;
    function Having: IHaving;
  end;

  IHaving = interface
    function FieldValue_(aField: TBaseField): IHavingNext;
    function Exists_   (const aSubQuery: IQueryBuilder): IHavingEnd;
    function NotExists_(const aSubQuery: IQueryBuilder): IHavingEnd;
    function Count_: IHaving;
    function CountDistinct_: IHaving;
    function Sum_: IHaving;
    function Min_: IHaving;
    function Max_: IHaving;
    function Average_: IHaving;

    function DateBetween_(const BeginField, EindField: TBaseField; Datum: TDateTime): IHavingEnd; overload;
    function DateBetween_(const BeginField, EindField, DatumField: TBaseField): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IHavingEnd; overload;

    function OpenBracket_  : IHaving;     // (
    function CloseBracket_ : IHavingEnd;  // )
    function AndHaving     : IHaving;
    function OrHaving      : IHaving;
  end;

  IHavingNext = interface(IHaving)
    function ISValue_       (const aValue: Variant): IHavingEnd;
    function ISNotValue_    (const aValue: Variant): IHavingEnd;
    function Equal_         (const aValue: Variant         ): IHavingEnd; overload;
    function Equal_         (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function NotEqual_      (const aValue: Variant         ): IHavingEnd; overload;
    function NotEqual_      (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function GreaterThan_   (const aValue: Variant         ): IHavingEnd; overload;
    function GreaterThan_   (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function GreaterOrEqual_(const aValue: Variant         ): IHavingEnd; overload;
    function GreaterOrEqual_(const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function LessThan_      (const aValue: Variant         ): IHavingEnd; overload;
    function LessThan_      (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function LessOrEqual_   (const aValue: Variant         ): IHavingEnd; overload;
    function LessOrEqual_   (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function Like_          (const aValue: string        ) : IHavingEnd;
    function InSet_         (const aSet: array of Variant): IHavingEnd; overload;
    function InSet_         (const aSet: array of Integer): IHavingEnd; overload;
    function InSet_         (const aSet: array of string): IHavingEnd; overload;
    function NotInSet_      (const aSet: array of Variant): IHavingEnd; overload;
    function NotInSet_         (const aSet: array of Integer): IHavingEnd; overload;
    function NotInSet_         (const aSet: array of string): IHavingEnd; overload;
    function EqualField_             (const aField: TBaseField): IHavingEnd;
    function NotEqualField_          (const aField: TBaseField): IHavingEnd;
    function GreaterThanField_       (const aField: TBaseField): IHavingEnd;
    function GreaterOrEqualField_    (const aField: TBaseField): IHavingEnd;
    function LessThanField_          (const aField: TBaseField): IHavingEnd;
    function LessOrEqualField_       (const aField: TBaseField): IHavingEnd;
    function IsNull_        ()                  : IHavingEnd;
    function IsNotNull_     ()                  : IHavingEnd;
  end;

  IHavingEnd = interface(IHaving)
    function AsQuery: IQueryBuilder;

    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;
  end;

  IOrdering = interface
    function AsQuery: IQueryBuilder;

    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;
  end;


  //================================
  IUpdateNext = interface;

  IUpdate = interface
    function SetField(aField: TBaseField)      : IUpdateNext;
    function IncrementField(aField: TBaseField): IUpdateNext;
  end;

  IUpdateNext = interface
    function WithValue(const aValue: Variant) : IUpdateEnd;
    function WithField(const aField: TBaseField): IUpdateEnd;
  end;

  IUpdateEnd = interface
    function SetField(aField: TBaseField)      : IUpdateNext;
    function IncrementField(aField: TBaseField): IUpdateNext;
    function InnerJoin                         : IJoin;
    function RightOuterJoin                    : IJoin;
    function LeftOuterJoin                     : IJoin;

    function Where: IWhere;
    function AndWhere: IWhere; overload;
    function AndWhere(aWhereObject: IWhere_Standalone): IWhere; overload;
    function OrWhere : IWhere; overload;
    function OrWhere(aWhereObject: IWhere_Standalone): IWhere; overload;
  end;

  //================================
  IDeleteWhere = interface;

  IDelete = interface
    function Where: IWhere;
    //function From(const aDatabase, aTable: string): IDeleteWhere;
  end;

  IDeleteWhere = interface
    function Where: IWhere;
  end;

  //================================
  IInsert = interface
    function SetFieldWithValue(aField: TBaseField; const aValue: Variant): IInsert;
    function SetFieldWithField(aField, aValueField: TBaseField): IInsert;
    function From(aRecord: TDataRecord): IJoinNext;

    procedure EnableIdentityInsert;
    procedure RetrieveIdentity;
  end;

  TBaseFieldValues = class(TDictionary<TBaseField,Variant>)
  public
    function GetFieldByName(const aFieldName: string): TBaseField;
  end;
  TInsertFieldValues = class(TBaseFieldValues);
  TUpdateFieldValues = class(TBaseFieldValues);

  TBaseFieldFields = class(TDictionary<TBaseField,TBaseField>)
  public
    function GetFieldByName(const aFieldName: string): TBaseField;
  end;
  TInsertFieldFields = class(TBaseFieldFields);
  TUpdateFieldFields = class(TBaseFieldFields);

  //********************************
  TWhereOperation = (woAnd, woOr, woOpenBracket, woCloseBracket, woField, woExists, woNotExists);
  TWhereCompare   = (wcEqual, wcEqualOrNull,  wcNotEqual, wcIs, wcIsNot, wcGreater, wcGreaterEqual,
                     wcLess, wcLessEqual, wcLike, wcNotLike, wcInSet, wcNotInSet, wcInQuerySet, wcNotInQuerySet, wcEqualField, wcNotEqualField,
                     wcGreaterField, wcGreaterEqualField, wcLessField, wcLessEqualField);

  TWherePart = class
    FOperation: TWhereOperation;
  end;
  //
  TWherePartField = class(TWherePart)
    FField   : TBaseField;
    FFieldSelectType: TSelectOperation;
    FCompare : TWhereCompare;
  end;
  //
  TWherePartFieldValue = class(TWherePartField)
  protected
    FCompareValue: Variant;
  public
    FCompareSubQuery: IQueryDetails;
    procedure AfterConstruction; override;
    property  CompareValue: Variant read FCompareValue write FCompareValue;
  end;
  //
  TWherePartFieldSet = class(TWherePartField)
  public
    FCompareSet: array of Variant;
    procedure AfterConstruction; override;
  end;
  //
  TWherePartFieldField = class(TWherePartField)
  public
    FCompareField: TBaseField;
    procedure AfterConstruction; override;
  end;
  //
  TWherePartSubQuery = class(TWherePart)
    FQuery: IQueryBuilder;
  end;

  TWherePartList = class(TObjectList<TWherePart>)
    function Fields: TFieldArray;
  end;

  TWhereBuilder = class(TInterfacedObject,
                        IWhere_Standalone, IWhereNext_Standalone,
                        IWhereDetails)
  private
    FWhereParts: TWherePartList;
    FActiveWhereField: TBaseField;
    FActiveWhereOperation: TSelectOperation;
    function CompareToValue(const aType: TWhereCompare; const aValue: Variant): IWhere_Standalone;
    function CompareToQuery(const aType: TWhereCompare; const aSubQuery: IQueryBuilder): IWhere_Standalone;
    function CompareToField(const aType: TWhereCompare; const aField: TBaseField): IWhere_Standalone;
  protected
    {IWhere_Standalone}
    function FieldValue(aField: TBaseField): IWhereNext_Standalone;
//    function IsNull    (aField: TBaseField): IWhere_Standalone;
    function OpenBracket  : IWhere_Standalone; // (
    function CloseBracket : IWhere_Standalone; // )
    function AndWhere     : IWhere_Standalone;
    function OrWhere      : IWhere_Standalone;
    function Exists   (const aSubQuery: IQueryBuilder): IWhere_Standalone;
    function NotExists(const aSubQuery: IQueryBuilder): IWhere_Standalone;
    {IWhereNext_Standalone}
    function ISValue       (const aValue: Variant): IWhere_Standalone;
    function ISNotValue    (const aValue: Variant): IWhere_Standalone;
    function Equal         (const aValue: Variant         ): IWhere_Standalone; overload;
    function Equal         (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function EqualOrNull   (const aValue: Variant         ): IWhere_Standalone; overload;
    function NotEqual      (const aValue: Variant         ): IWhere_Standalone; overload;
    function NotEqual      (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function GreaterThan   (const aValue: Variant         ): IWhere_Standalone; overload;
    function GreaterThan   (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function GreaterOrEqual(const aValue: Variant         ): IWhere_Standalone; overload;
    function GreaterOrEqual(const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function LessThan      (const aValue: Variant         ): IWhere_Standalone; overload;
    function LessThan      (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function LessOrEqual   (const aValue: Variant         ): IWhere_Standalone; overload;
    function LessOrEqual   (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function Like          (const aValue: string) : IWhere_Standalone;
    function NotLike       (const aValue: string) : IWhere_Standalone;
    function InSet         (const aSet: array of Variant): IWhere_Standalone; overload;
    function InSet         (const aSet: array of Integer): IWhere_Standalone; overload;
    function InSet         (const aSet: array of string):  IWhere_Standalone; overload;
    function InSet         (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function NotInSet      (const aSet: array of Variant): IWhere_Standalone; overload;
    function NotInSet      (const aSet: array of Integer): IWhere_Standalone; overload;
    function NotInSet      (const aSet: array of string):  IWhere_Standalone; overload;
    function NotInSet      (const aSubQuery: IQueryBuilder): IWhere_Standalone; overload;
    function EqualField             (const aField: TBaseField): IWhere_Standalone;
    function NotEqualField          (const aField: TBaseField): IWhere_Standalone;
    function GreaterThanField       (const aField: TBaseField): IWhere_Standalone;
    function GreaterOrEqualField    (const aField: TBaseField): IWhere_Standalone;
    function LessThanField          (const aField: TBaseField): IWhere_Standalone;
    function LessOrEqualField       (const aField: TBaseField): IWhere_Standalone;

    function IsNull        (): IWhere_Standalone;
    function IsNotNull     (): IWhere_Standalone;
    {IWhereDetails}
    function WhereParts: TWherePartList;
    {IHaving}
    function Count         : IWhere_Standalone;
    function CountDistinct: IWhere_Standalone;
    function Sum: IWhere_Standalone;
    function Min: IWhere_Standalone;
    function Max: IWhere_Standalone;
    function Average: IWhere_Standalone;
  public
    procedure   AfterConstruction; override;
    destructor  Destroy; override;
  end;

  //********************************
  TJoinOperation = (joInnerJoin, joLeftJoin, joRightJoin, joAnd, joOr, joOpenBracket, joCloseBracket, joField, joSubQuery);
//  TJoinCompare   = (jcEqual, jcNotEqual, jcIs, jcIsNot, jcGreater, jcGreaterEqual,
//                    jcLess, jcLessEqual, jcLike, jcInSet, jcNotInSet, jcEqualField, jcNotEqualField);

  TJoinPart = class
    FOperation: TJoinOperation;
  end;
  //
  TJoinPartField = class(TJoinPart)
    FJoinField: TBaseField;
    FTableHints: TTableHints;
    FCompare  : TJoinCompare;
  end;
  //
  TJoinPartFieldValue = class(TJoinPartField)
  protected
    FJoinValue: Variant;
  public
    procedure AfterConstruction; override;
    property  JoinValue: Variant read FJoinValue write FJoinValue;
  end;
  //
  TJoinPartFieldSet = class(TJoinPartField)
  public
    FJoinSet: array of Variant;
    procedure AfterConstruction; override;
  end;
  //
  TJoinPartFieldField = class(TJoinPartField)
  public
    FSourceField: TBaseField;
    procedure AfterConstruction; override;
  end;
  //
  TJoinPartSubQuery = class(TJoinPart)
    FSubQuery: IQueryDetails;
  end;

  TJoinPartList = class(TObjectList<TJoinPart>)
    function JoinFieldExist(aSourceField: TCustomField): Boolean;
    function Fields: TFieldArray;
  end;

  //********************************
  TOrderByOperation = (obAsc, obDesc);

  TOrderByPart = class
  public
    FOperation: TOrderByOperation;
    FOrderByField: TBaseField;
  end;

  TOrderByPartList = class(TObjectList<TOrderByPart>);

  //********************************

  TGroupByPart = class
  public
    FGroupBySet: array of TBaseField;
  end;

  //********************************

  TQueryBuilder = class(TInterfacedObject,
                        IQueryBuilder,
                        IQueryDetails,
                        ISelect, ISelectNext,
                        IJoin, IJoinNext,
                        IWhere, IWhereNext, IWhereEnd,
                        IGrouping, IGroupingNext,
                        IOrdering,
                        //
                        IUpdate, IUpdateEnd, IUpdateNext,
                        //
                        IDelete, IDeleteWhere,
                        IInsert,
                        //
                        IHaving, IHavingNext, IHavingEnd)
  protected
    //FDatabase,
    FTable: string;
    FMainTableField: TBaseField;

    type
//    TTableAlias = record
//      TableName: string;
//      AliasName: String;
//    end;
    TAliasList = class(TDictionary<string,string>);
    var FAliases: TObjectDictionary<TDataRecord,TAliasList>;
    var FAllAliases: TList<string>;
  protected
    FQueryType: TQueryType;
    FSelectFields: TSelectFields;
    FSelectFields_Ordered: TFieldList;
    FSelectFieldsSubqueries: TList<IQueryDetails>;
    FFromSubQuery: IQueryDetails;

    FTopCount: Integer;
    FDoDistinct: Boolean;
    FTableHints: TTableHints;

    FWhereBuilder: TWhereBuilder;
    FHavingBuilder: TWhereBuilder;

    FInsertFromRecord: TDataRecord;
    FInsertFieldValues: TInsertFieldValues;
    FInsertFieldFields: TInsertFieldFields;
    FEnableIdentityInsert,
    FRetrieveIdentity: Boolean;

    FActiveIncField,
    FActiveUpdateField: TBaseField;
    FIncrementFieldValues: TUpdateFieldValues;
    FUpdateFieldValues: TUpdateFieldValues;
    FIncrementFieldFields: TUpdateFieldFields;
    FUpdateFieldFields: TUpdateFieldFields;

    FJoinPartList: TJoinPartList;
    FOrderByPartList: TOrderByPartList;
    FGroupByPart: TGroupByPart;

    procedure DetermineAliasForField(aField: TBaseField);
  protected
    {IQueryBuilder}
    function Select: ISelect;
    function CurrentSelect: ISelectNext;
    function CurrentInsert: IInsert;
    function CurrentUpdate: IUpdateEnd;
    function Update: IUpdate;
    function Delete: IDelete;
    function Insert: IInsert;
    function Details: IQueryDetails;
  protected
    FParentQuery: IQueryDetails;

    {IQueryDetails}
    function QueryType   : TQueryType;

//    function Database: string;
    function Table: string;
    function MainTableField: TBaseField;
    function FromSubQuery: IQueryDetails; overload;

    procedure SetParentQuery(aParent: IQueryDetails);  //in case of subqueries
    function AliasCount: Integer;
    function GetAliasForField(aField: TBaseField): string;

    function DoTopCount: Integer;
    function DoDistinct: Boolean;
    function TableHints: TTableHints;

    function SelectFields: TSelectFields;
    function SelectFields_Ordered: TFieldList;
    function SelectFieldsSubqueries: TList<IQueryDetails>;
    //
    function WhereParts: TWherePartList;
    function HavingParts: TWherePartList;
    //
    function JoinParts : TJoinPartList;
    function OrderByParts: TOrderByPartList;
    function GroupByPart: TGroupByPart;

    function InsertFromRecord: TDataRecord;
    function InsertFieldValues: TInsertFieldValues;
    function InsertFieldFields: TInsertFieldFields;
    function RetrieveIdentityAfterInsert: Boolean;
    function ActivateIdentityInsert: Boolean;

    function UpdateFieldValues: TUpdateFieldValues;
    function UpdateIncFieldValues: TUpdateFieldValues;
    function UpdateFieldFields: TUpdateFieldFields;
    function UpdateIncFieldFields: TUpdateFieldFields;
  protected
    {ISelect}
    function TopCount(aRecords: Integer): ISelect;
    function Distinct: ISelect;
    function AllFieldsOf  (aFields: TDataRecord        )  : ISelectNext;
    function Fields       (aFields: array of TBaseField)  : ISelectNext;
    function Sum          (aField: TBaseField)            : ISelectNext; overload;
    function Count        (aField: TBaseField)            : ISelectNext; overload;
    function CountDistinct(aField: TBaseField)            : ISelectNext; overload;
    function Average      (aField: TBaseField)            : ISelectNext; overload;
    function Min          (aField: TBaseField)            : ISelectNext; overload;
    function Max          (aField: TBaseField;
                           const aResultField: TBaseField = nil): ISelectNext; overload;
    function SubQueryField(aSubQuery: IQueryBuilder): ISelectNext;
    function FromSubQuery (aSubQuery: IQueryBuilder): ISelectNext; overload;
    {ISelectNext}
    function InnerJoin     : IJoin;
    function RightOuterJoin: IJoin;
    function LeftOuterJoin : IJoin;

    function Where   : IWhere;
    function AndWhere: IWhere; overload;
    function OrWhere : IWhere; overload;
    function AndWhere(aWhereObject: IWhere_Standalone): IWhere; overload;
    function OrWhere (aWhereObject: IWhere_Standalone): IWhere; overload;

    function GroupBy(const aFields: array of TBaseField): IGroupingNext;
    function OrderBy          (aField: TBaseField): IOrdering;
    function OrderByDescending(aField: TBaseField): IOrdering;

    function WithTableHints(aHints: TTableHints): ISelectNext;
    function AsQuery: IQueryBuilder;
  protected
    {IWhere}
    function FieldValue(aField: TBaseField): IWhereNext;
//    function IsNull    (aField: TBaseField): IWhereEnd;
    function OpenBracket  : IWhere;    overload; // (
    function CloseBracket : IWhereEnd; overload; // )
    function Exists   (const aSubQuery: IQueryBuilder): IWhereEnd;
    function NotExists(const aSubQuery: IQueryBuilder): IWhereEnd;
    function DateBetween(const BeginField, EindField: TBaseField; Datum: TDateTime): IWhereEnd; overload;
    function DateBetween(const BeginField, EindField, DatumField: TBaseField): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IWhereEnd; overload;
    function PointInTime(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IWhereEnd; overload;
    {IWhereNext}
    function ISValue       (const aValue: Variant): IWhereEnd;
    function ISNotValue    (const aValue: Variant): IWhereEnd;
    function Equal         (const aValue: Variant         ): IWhereEnd; overload;
    function Equal         (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function EqualOrNull   (const aValue: Variant         ): IWhereEnd; overload;
    function NotEqual      (const aValue: Variant         ): IWhereEnd; overload;
    function NotEqual      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function GreaterThan   (const aValue: Variant         ): IWhereEnd; overload;
    function GreaterThan   (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function GreaterOrEqual(const aValue: Variant         ): IWhereEnd; overload;
    function GreaterOrEqual(const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function LessThan      (const aValue: Variant         ): IWhereEnd; overload;
    function LessThan      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function LessOrEqual   (const aValue: Variant         ): IWhereEnd; overload;
    function LessOrEqual   (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function Like          (const aValue: string) : IWhereEnd;
    function NotLike       (const aValue: string) : IWhereEnd;
    function InSet         (const aSet: array of Variant): IWhereEnd; overload;
    function InSet         (const aSet: array of Integer): IWhereEnd; overload;
    function InSet         (const aSet: array of string): IWhereEnd; overload;
    function InSet         (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function NotInSet      (const aSet: array of Variant): IWhereEnd; overload;
    function NotInSet      (const aSet: array of Integer): IWhereEnd; overload;
    function NotInSet      (const aSet: array of string): IWhereEnd; overload;
    function NotInSet      (const aSubQuery: IQueryBuilder): IWhereEnd; overload;
    function EqualField             (const aField: TBaseField): IWhereEnd;
    function NotEqualField          (const aField: TBaseField): IWhereEnd;
    function GreaterThanField       (const aField: TBaseField): IWhereEnd;
    function GreaterOrEqualField    (const aField: TBaseField): IWhereEnd;
    function LessThanField          (const aField: TBaseField): IWhereEnd;
    function LessOrEqualField       (const aField: TBaseField): IWhereEnd;
    function IsNull        (): IWhereEnd;
    function IsNotNull     (): IWhereEnd;
  protected
    {IJoin}
    function OnFields          (aJoinTableField, aValueTableField: TBaseField): IJoinNext;
    function OnFieldAndValue   (aJoinTableField: TBaseField; const aValue: Variant) : IJoinNext;
    function OnFieldAndNotValue(aJoinTableField: TBaseField; const aValue: Variant) : IJoinNext;
    function OnFieldCompare    (aJoinTableField: TBaseField; aCompare: TJoinCompare; const aValue: Variant): IJoinNext; overload;
    function OnFieldCompare    (aJoinTableField: TBaseField; aCompare: TJoinCompare; const aCompareField: TBaseFIeld): IJoinNext; overload;
    function OnFieldInSet      (aJoinTableField: TBaseField; const aValues: array of Variant): IJoinNext;
    function SubQuery(aSubQuery: IQueryBuilder): IJoin;
    function OpenJoinBracket : IJoin; overload;  // (
    function CloseJoinBracket: IJoin; overload;  // )
    {IJoinNext}
    function AndJoin: IJoin;
    function OrJoin : IJoin;
    function CloseJoinBracketN: IJoinNext;   // )
    function WithJoinTableHints(aHints: TTableHints): IJoinNext;
  protected
    {IInsert}
    function  SetFieldWithValue(aField: TBaseField; const aValue: Variant): IInsert;
    function  SetFieldWithField(aField, aValueField: TBaseField): IInsert;
    function  From(aRecord: TDataRecord): IJoinNext;
    procedure EnableIdentityInsert;
    procedure RetrieveIdentity;
  protected
    {IUpdate}
    function IncrementField(aField: TBaseField): IUpdateNext;
    function SetField(aField: TBaseField)      : IUpdateNext;
    function WithValue(const aValue: Variant) : IUpdateEnd;
    function WithField(const aField: TBaseField): IUpdateEnd;
  protected
    {IDelete}
//    function From(const aDatabase, aTable: string): IDeleteWhere;
  protected
    function Having: IHaving;
     {IHaving}
    function FieldValue_(aField: TBaseField): IHavingNext;
    function Exists_   (const aSubQuery: IQueryBuilder): IHavingEnd;
    function NotExists_(const aSubQuery: IQueryBuilder): IHavingEnd;
    function Count_            : IHaving;
    function CountDistinct_    : IHaving;
    function Average_          : IHaving;
    function Min_              : IHaving;
    function Max_              : IHaving;
    function Sum_              : IHaving;

    function DateBetween_(const BeginField, EindField: TBaseField; Datum: TDateTime): IHavingEnd; overload;
    function DateBetween_(const BeginField, EindField, DatumField: TBaseField): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IHavingEnd; overload;
    function PointInTime_(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IHavingEnd; overload;

    function OpenBracket_  : IHaving;     // (
    function CloseBracket_ : IHavingEnd;  // )
    function AndHaving     : IHaving;
    function OrHaving      : IHaving;
     {IHavingNext}
    function ISValue_       (const aValue: Variant): IHavingEnd;
    function ISNotValue_    (const aValue: Variant): IHavingEnd;
    function Equal_         (const aValue: Variant         ): IHavingEnd; overload;
    function Equal_         (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function NotEqual_      (const aValue: Variant         ): IHavingEnd; overload;
    function NotEqual_      (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function GreaterThan_   (const aValue: Variant         ): IHavingEnd; overload;
    function GreaterThan_   (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function GreaterOrEqual_(const aValue: Variant         ): IHavingEnd; overload;
    function GreaterOrEqual_(const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function LessThan_      (const aValue: Variant         ): IHavingEnd; overload;
    function LessThan_      (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function LessOrEqual_   (const aValue: Variant         ): IHavingEnd; overload;
    function LessOrEqual_   (const aSubQuery: IQueryBuilder): IHavingEnd; overload;
    function Like_          (const aValue: string        ) : IHavingEnd;
    function InSet_         (const aSet: array of Variant): IHavingEnd; overload;
    function InSet_         (const aSet: array of Integer): IHavingEnd; overload;
    function InSet_         (const aSet: array of string): IHavingEnd; overload;
    function NotInSet_      (const aSet: array of Variant): IHavingEnd; overload;
    function NotInSet_         (const aSet: array of Integer): IHavingEnd; overload;
    function NotInSet_         (const aSet: array of string): IHavingEnd; overload;
    function EqualField_             (const aField: TBaseField): IHavingEnd;
    function NotEqualField_          (const aField: TBaseField): IHavingEnd;
    function GreaterThanField_       (const aField: TBaseField): IHavingEnd;
    function GreaterOrEqualField_    (const aField: TBaseField): IHavingEnd;
    function LessThanField_          (const aField: TBaseField): IHavingEnd;
    function LessOrEqualField_       (const aField: TBaseField): IHavingEnd;
    function IsNull_        ()                  : IHavingEnd;
    function IsNotNull_     ()                  : IHavingEnd;
  public
    //constructor Create(const aDatabase, aTable: string); virtual;
    constructor Create(const aMainTableField: TBaseField);
    procedure   AfterConstruction; override;
    destructor  Destroy; override;
  end;

implementation

uses
  SysUtils, Variants, Data.CustomSQLFields;

{ TQueryBuilder }

function TQueryBuilder.ActivateIdentityInsert: Boolean;
begin
  Result := FEnableIdentityInsert;
end;

procedure TQueryBuilder.AfterConstruction;
begin
  inherited;
  FSelectFields := TSelectFields.Create;
  FSelectFields_Ordered := TFieldList.Create;
  //FWhereParts   := TWherePartList.Create(True{owns});
  FWhereBuilder := TWhereBuilder.Create;
  FWhereBuilder._AddRef;
  FHavingBuilder := TWhereBuilder.Create;
  FHavingBuilder._AddRef;

  FAliases  := TObjectDictionary<TDataRecord, TAliasList>.Create([doOwnsValues]);
  FAllAliases := TList<string>.Create;
  if FMainTableField <> nil then
    DetermineAliasForField(FMainTableField);

  FJoinPartList := TJoinPartList.Create(True);
  FOrderByPartList := TOrderByPartList.Create;

  FTopCount := -1;
end;

function TQueryBuilder.AliasCount: Integer;
begin
  Result := FAllAliases.Count;
end;

function TQueryBuilder.AllFieldsOf(aFields: TDataRecord): ISelectNext;
var
  f: TBaseField;
begin
  Result := Self;
  for f in aFields do
  begin
    if (f.TableName = '') and (not (f is TCustomSQLField)) then Continue;

    FSelectFields.Add(f, soSelect);
    FSelectFields_Ordered.Add(f);
    DetermineAliasForField(f);
  end;
end;

function TQueryBuilder.AndJoin: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joAnd;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.AndWhere(aWhereObject: IWhere_Standalone): IWhere;
var
  wb: TWhereBuilder;
begin
  Assert(aWhereObject is TWhereBuilder);
  wb := (aWhereObject as TWhereBuilder);
  FWhereBuilder.AndWhere.OpenBracket;
  FWhereBuilder.FWhereParts.AddRange( wb.FWhereParts.ToArray );
  FWhereBuilder.CloseBracket;

  //todo: make a clone?
  wb.FWhereParts.OwnsObjects := False;
  try
    wb.FWhereParts.Clear;
  finally
    wb.FWhereParts.OwnsObjects := True;
  end;
end;

function TQueryBuilder.Details: IQueryDetails;
begin
   Result := Self;
end;

function TQueryBuilder.AsQuery: IQueryBuilder;
begin
  Result := Self;
end;

function TQueryBuilder.AndWhere: IWhere;
begin
  Result := Self;
  FWhereBuilder.AndWhere;
end;

function TQueryBuilder.Average(aField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FSelectFields.Add(aField, soAvg);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.CloseBracket: IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.CloseBracket;
end;

function TQueryBuilder.CloseJoinBracket: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joCloseBracket;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.CloseJoinBracketN: IJoinNext;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joCloseBracket;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.Count(aField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FSelectFields.Add(aField, soCount);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.CountDistinct(aField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FSelectFields.Add(aField, soCountDistinct);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.Count_: IHaving;
begin
   Result := Self;
   FHavingBuilder.Count;
end;

function TQueryBuilder.CountDistinct_: IHaving;
begin
   Result := Self;
   FHavingBuilder.CountDistinct;
end;

function TQueryBuilder.Average_: IHaving;
begin
   Result := Self;
   FHavingBuilder.Average;
end;

function TQueryBuilder.Min_: IHaving;
begin
   Result := Self;
   FHavingBuilder.Min;
end;

function TQueryBuilder.Max_: IHaving;
begin
   Result := Self;
   FHavingBuilder.Max;
end;

function TQueryBuilder.Sum_: IHaving;
begin
   Result := Self;
   FHavingBuilder.Sum;
end;

constructor TQueryBuilder.Create(const aMainTableField: TBaseField);
begin
  FTable    := aMainTableField.TableName;
  FMainTableField := aMainTableField;
end;

function TQueryBuilder.CurrentSelect: ISelectNext;
begin
  Result := Self;
end;

function TQueryBuilder.CurrentInsert: IInsert;
begin
  Result := Self;
end;

function TQueryBuilder.CurrentUpdate: IUpdateEnd;
begin
  Result := Self;
end;

function TQueryBuilder.Delete: IDelete;
begin
  Result := Self;
  Self.FQueryType := qtDelete;
end;

destructor TQueryBuilder.Destroy;
begin
  FSelectFieldsSubqueries.Free;
  FAllAliases.Free;
  FJoinPartList.Free;
  FOrderByPartList.Free;
  FAliases.Free;
  FSelectFields.Free;
  FSelectFields_Ordered.Free;
  //FWhereParts.Free;
  //FWhereBuilder.Free;
  FWhereBuilder._Release;
  FHavingBuilder._Release;
  FInsertFieldValues.Free;
  FInsertFieldFields.Free;
  FIncrementFieldValues.Free;
  FUpdateFieldValues.Free;
  FUpdateFieldFields.Free;
  FIncrementFieldFields.Free;
  FGroupByPart.Free;
  inherited;
end;

procedure TQueryBuilder.DetermineAliasForField(aField: TBaseField);
var
  aliases: TAliasList;
  svalue: string;
  i: Integer;
  firstLetter: Char;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));

  Assert(Assigned(aField.DataRecord), aField.FieldName+' heeft geen datarecord');
  if not FAliases.TryGetValue(aField.DataRecord, aliases) then
  begin
    aliases := TAliasList.Create;
    FAliases.Add(aField.DataRecord, aliases);
  end;

  if (aField is TCustomSQLField) then Exit;

  //no alias exists yet? then generate one
  if not aliases.ContainsKey(aField.TableClassName) then
  begin
    i := 1;
    Assert(aField.TableName <> '');
    //todo: CamelCase search? or generate alias in generator?
    firstLetter := aField.TableName[1];
    while (not CharInSet(firstLetter, ['a'..'z','A'..'Z'])) do // #TempTable -> skip #
    begin
      Inc(i);
      firstLetter := aField.TableName[i];
    end;

    svalue := LowerCase(firstLetter);
    i := 0;
    while FAllAliases.Contains(svalue) do   //check if alias is unique for whole query
    begin
      Inc(i);
      svalue := LowerCase(firstLetter) + IntToStr(i);
    end;
    aliases.Add(aField.TableClassName, svalue);
    FAllAliases.Add(svalue);
  end;
end;

function TQueryBuilder.Distinct: ISelect;
begin
  Result := Self;
  FDoDistinct := True;
end;

function TQueryBuilder.DoDistinct: Boolean;
begin
  Result := FDoDistinct;
end;

procedure TQueryBuilder.EnableIdentityInsert;
begin
  FEnableIdentityInsert := True;
end;

function TQueryBuilder.Equal(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.Equal(aValue);
end;

function TQueryBuilder.Equal(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.Equal(aSubQuery);
end;

function TQueryBuilder.EqualField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.EqualField(aField);
end;

function TQueryBuilder.EqualOrNull(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.EqualOrNull(aValue);
end;

function TQueryBuilder.Exists(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.Exists(aSubQuery);
end;

function TQueryBuilder.Fields(aFields: array of TBaseField): ISelectNext;
var
  f: TBaseField;
begin
  Result := Self;
  for f in aFields do
  begin
    if f is TCustomCalculatedField then Continue;
    if f is TNonQueryField then Continue;

    DetermineAliasForField(f);
    FSelectFields.Add(f, soSelect);
    FSelectFields_Ordered.Add(f);
  end;
end;

function TQueryBuilder.FieldValue(aField: TBaseField): IWhereNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FWhereBuilder.FieldValue(aField);
end;

function TQueryBuilder.FromSubQuery: IQueryDetails;
begin
  Result := FFromSubQuery;
end;

function TQueryBuilder.FromSubQuery(aSubQuery: IQueryBuilder): ISelectNext;
begin
  Result := Self;
  FFromSubQuery := aSubQuery as IQueryDetails;
end;

function TQueryBuilder.GetAliasForField(aField: TBaseField): string;
var
  aliaslist: TAliasList;
begin
  //subqueries must ask parent for "global" alias
  if FParentQuery <> nil then
    Exit( FParentQuery.GetAliasForField(aField) );

  Result := '';
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  if (aField is TCustomSQLField) then
  begin // is geen echt DB veld, 1e databaseveld gebruiken
    Assert(Length((aField as TCustomSQLField).GetRequiredFields) > 0);
    Exit(GetAliasForField((aField as TCustomSQLField).GetRequiredFields[0]))
  end;

  //first search alias list for datarecord/model
  if not FAliases.TryGetValue(aField.DataRecord, aliaslist) then
  begin
    DetermineAliasForField(aField);
    if not FAliases.TryGetValue(aField.DataRecord, aliaslist) then
      Assert(False);
  end;
  //then search for alias of this table (in case of combi model with different tables)
  if not aliaslist.TryGetValue(aField.TableClassName, Result) then
  begin
    DetermineAliasForField(aField);
    if not aliaslist.TryGetValue(aField.TableClassName, Result) then
      Assert(False);
  end;
end;

function TQueryBuilder.GreaterOrEqual(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterOrEqual(aValue);
end;

function TQueryBuilder.GreaterThan(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterThan(aValue);
end;

function TQueryBuilder.GroupBy(const aFields: array of TBaseField): IGroupingNext;
var
  gb: TGroupByPart;
  i: Integer;
begin
  Result := Self;

  gb := TGroupByPart.Create;
  SetLength(gb.FGroupBySet, Length(aFields));
  for i := 0 to High(aFields) do
    gb.FGroupBySet[i] := aFields[i];
  Self.FGroupByPart := gb;
end;

function TQueryBuilder.IncrementField(aField: TBaseField): IUpdateNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  if FIncrementFieldValues = nil then
    FIncrementFieldValues := TUpdateFieldValues.Create;
  if FIncrementFieldFields = nil then
    FIncrementFieldFields := TUpdateFieldFields.Create;
  FActiveIncField    := aField;
  FActiveUpdateField := nil;
end;

function TQueryBuilder.InnerJoin: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joInnerJoin;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.Insert: IInsert;
begin
  Result := Self;
  Self.FQueryType := qtInsert;

  if FInsertFieldValues = nil then
    FInsertFieldValues := TInsertFieldValues.Create;
  if FInsertFieldFields = nil then
    FInsertFieldFields := TInsertFieldFields.Create;
end;

function TQueryBuilder.InsertFieldFields: TInsertFieldFields;
begin
  Result := FInsertFieldFields;
end;

function TQueryBuilder.InsertFromRecord: TDataRecord;
begin
   Result := FInsertFromRecord;
end;

function TQueryBuilder.InsertFieldValues: TInsertFieldValues;
begin
  Result := FInsertFieldValues;
end;

function TQueryBuilder.InSet(const aSet: array of Integer): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.InSet(aSet);
end;

function TQueryBuilder.InSet(const aSet: array of string): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.InSet(aSet);
end;

function TQueryBuilder.InSet(const aSet: array of Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.InSet(aSet);
end;

function TQueryBuilder.ISNotValue(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.ISNotValue(aValue);
end;

function TQueryBuilder.IsNull(): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.IsNull();
end;

function TQueryBuilder.IsNotNull: IWhereEnd;
begin
    Result := Self;
    FWhereBuilder.IsNotNull();
end;

function TQueryBuilder.DateBetween(const BeginField, EindField: TBaseField; Datum: TDateTime): IWhereEnd;
begin
   // TODO: dit ook daadwerkelijk omschrijven naar 'Datum' between BeginField and IsNull(EindField, Datum)
   Result := PointInTime(BeginField, EindField, Datum, Datum);
end;

function TQueryBuilder.DateBetween(const BeginField, EindField, DatumField: TBaseField): IWhereEnd;
begin
   Result := PointInTime(BeginField, EindField, DatumField, DatumField);
end;

function TQueryBuilder.PointInTime(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IWhereEnd;
begin
   Result := FieldValue(BeginField).LessOrEqual(BeginDatum)
      .AndWhere.OpenBracket.FieldValue(EindField).IsNull.OrWhere.FieldValue(EindField).GreaterOrEqual(EindDatum).CloseBracket
end;

function TQueryBuilder.PointInTime(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IWhereEnd;
begin
   Result := FieldValue(BeginField).LessOrEqualField(BeginDatumField)
      .AndWhere.OpenBracket.FieldValue(EindField).IsNull.OrWhere.FieldValue(EindField).GreaterOrEqualField(EindDatumField).CloseBracket
end;

function TQueryBuilder.PointInTime(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IWhereEnd;
begin
   Result := FieldValue(BeginField).LessOrEqualField(BeginDatumField)
      .AndWhere.OpenBracket.FieldValue(EindField).IsNull.OrWhere.FieldValue(EindField).GreaterOrEqual(EindDatum).CloseBracket
end;

function TQueryBuilder.PointInTime(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IWhereEnd;
begin
   Result := FieldValue(BeginField).LessOrEqual(BeginDatum)
      .AndWhere.OpenBracket.FieldValue(EindField).IsNull.OrWhere.FieldValue(EindField).GreaterOrEqualField(EindDatumField).CloseBracket
end;

function TQueryBuilder.ISValue(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.ISValue(aValue);
end;

function TQueryBuilder.JoinParts: TJoinPartList;
begin
  Result := FJoinPartList;
end;

function TQueryBuilder.OrderByParts: TOrderByPartList;
begin
   Result := FOrderByPartList;
end;

function TQueryBuilder.GroupByPart: TGroupByPart;
begin
   Result := FGroupByPart;
end;

function TQueryBuilder.LeftOuterJoin: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joLeftJoin;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.LessOrEqual(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessOrEqual(aValue);
end;

function TQueryBuilder.LessThan(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessThan(aValue);
end;

function TQueryBuilder.Like(const aValue: string): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.Like(aValue);
end;

function TQueryBuilder.MainTableField: TBaseField;
begin
  Result := FMainTableField;
end;

function TQueryBuilder.Max(aField: TBaseField;
  const aResultField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Result := Self;
  FSelectFields.Add(aField, soMax);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.Min(aField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FSelectFields.Add(aField, soMin);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.NotEqual(const aValue: Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotEqual(aValue);
end;

function TQueryBuilder.NotEqual(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotEqual(aSubQuery);
end;

function TQueryBuilder.NotEqualField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotEqualField(aField);
end;

function TQueryBuilder.NotExists(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotExists(aSubQuery);
end;

function TQueryBuilder.NotInSet(const aSet: array of Variant): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotInSet(aSet);
end;

function TQueryBuilder.NotInSet(const aSet: array of Integer): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotInSet(aSet);
end;

function TQueryBuilder.NotInSet(const aSet: array of String): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.NotInSet(aSet);
end;

function TQueryBuilder.OnFieldAndNotValue(aJoinTableField: TBaseField;
  const aValue: Variant): IJoinNext;
var jp: TJoinPartFieldValue;
begin
  Result := Self;
  jp := TJoinPartFieldValue.Create;
  jp.FJoinField    := aJoinTableField;
  if VarIsNull(aValue) then
  begin
    jp.FCompare      := jcIsNot;
    jp.FJoinValue    := null;
  end
  else
  begin
    jp.FCompare      := jcNotEqual;
    jp.FJoinValue    := aValue;
  end;
  FJoinPartList.Add(jp);
  DetermineAliasForField(aJoinTableField);
end;

function TQueryBuilder.OnFieldAndValue(aJoinTableField: TBaseField;
  const aValue: Variant): IJoinNext;
var jp: TJoinPartFieldValue;
begin
  Result := Self;
  jp := TJoinPartFieldValue.Create;
  jp.FJoinField    := aJoinTableField;
  if VarIsNull(aValue) then
  begin
    jp.FCompare      := jcIs;
    jp.FJoinValue    := null;
  end
  else
  begin
    jp.FCompare      := jcEqual;
    jp.FJoinValue    := aValue;
  end;
  FJoinPartList.Add(jp);
  DetermineAliasForField(aJoinTableField);
end;

function TQueryBuilder.OnFieldCompare(aJoinTableField: TBaseField;
  aCompare: TJoinCompare; const aValue: Variant): IJoinNext;
var jp: TJoinPartFieldValue;
begin
  Result := Self;
  Assert(aCompare in [jcEqual, jcNotEqual, jcIs, jcIsNot, jcGreater, jcGreaterEqual, jcLess, jcLessEqual, jcLike, jcInSet, jcNotInSet]);
  jp := TJoinPartFieldValue.Create;
  jp.FJoinField    := aJoinTableField;
  if (aCompare in [jcEqual, jcNotEqual]) and
     VarIsNull(aValue) then
  begin
    if aCompare = jcEqual then
      jp.FCompare  := jcIs
    else if aCompare = jcNotEqual then
      jp.FCompare  := jcIsNot
    else Assert(False);
  end
  else
    jp.FCompare      := aCompare;
  jp.FJoinValue    := aValue;
  FJoinPartList.Add(jp);
  DetermineAliasForField(aJoinTableField);
end;

function TQueryBuilder.OnFieldCompare(aJoinTableField: TBaseField; aCompare: TJoinCompare; const aCompareField: TBaseFIeld): IJoinNext;
var jp: TJoinPartFieldField;
begin
  Result := Self;
  Assert(aCompare in [jcEqualField, jcNotEqualField, jcGreaterField, jcGreaterEqualField, jcLessField, jcLessEqualField]);
  jp := TJoinPartFieldField.Create;
  jp.FCompare := aCompare;
  jp.FJoinField    := aJoinTableField;
  jp.FSourceField    := aCompareField;
  FJoinPartList.Add(jp);
  DetermineAliasForField(aJoinTableField);
end;

function TQueryBuilder.OnFieldInSet(aJoinTableField: TBaseField; const aValues: array of Variant): IJoinNext;
var jp: TJoinPartFieldSet;
  i: Integer;
begin
  Result := Self;
  jp := TJoinPartFieldSet.Create;
  jp.FCompare      := jcInSet;
  jp.FJoinField    := aJoinTableField;
  SetLength(jp.FJoinSet, Length(aValues));
  for i := 0 to High(aValues) do
    jp.FJoinSet[i] := aValues[i];
  FJoinPartList.Add(jp);
  DetermineAliasForField(aJoinTableField);
end;

function TQueryBuilder.OnFields(aJoinTableField, aValueTableField: TBaseField): IJoinNext;
var jp: TJoinPartFieldField;
begin
  Result := Self;
  jp := TJoinPartFieldField.Create;
  jp.FCompare      := jcEqualField;
  jp.FJoinField    := aJoinTableField;
  jp.FSourceField  := aValueTableField;
  FJoinPartList.Add(jp);

  DetermineAliasForField(aJoinTableField);
  DetermineAliasForField(aValueTableField);
end;

function TQueryBuilder.OpenJoinBracket: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joOpenBracket;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.OpenBracket: IWhere;
begin
  Result := Self;
  FWhereBuilder.OpenBracket;
end;

function TQueryBuilder.OrderBy(aField: TBaseField): IOrdering;
var op: TOrderByPart;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  op := TOrderByPart.Create;
  op.FOperation := obAsc;
  op.FOrderByField := aField;

  FOrderByPartList.Add(op);
end;

function TQueryBuilder.OrderByDescending(aField: TBaseField): IOrdering;
var op: TOrderByPart;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  op := TOrderByPart.Create;
  op.FOperation := obDesc;
  op.FOrderByField := aField;

  FOrderByPartList.Add(op);
end;

function TQueryBuilder.OrJoin: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joOr;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.OrWhere(aWhereObject: IWhere_Standalone): IWhere;
var
  wb: TWhereBuilder;
begin
  Assert(aWhereObject is TWhereBuilder);
  wb := (aWhereObject as TWhereBuilder);
  FWhereBuilder.OrWhere.OpenBracket;
  FWhereBuilder.FWhereParts.AddRange( wb.FWhereParts.ToArray );
  FWhereBuilder.CloseBracket;

  //todo: make a clone?
  wb.FWhereParts.OwnsObjects := False;
  try
    wb.FWhereParts.Clear;
  finally
    wb.FWhereParts.OwnsObjects := True;
  end;
end;

function TQueryBuilder.OrWhere: IWhere;
begin
  Result := Self;
  FWhereBuilder.OrWhere;
end;

function TQueryBuilder.QueryType: TQueryType;
begin
  Result := FQueryType;
end;

procedure TQueryBuilder.RetrieveIdentity;
begin
  FRetrieveIdentity := True;
end;

function TQueryBuilder.RetrieveIdentityAfterInsert: Boolean;
begin
  Result := FRetrieveIdentity;
end;

function TQueryBuilder.RightOuterJoin: IJoin;
var jp: TJoinPart;
begin
  Result := Self;
  jp := TJoinPart.Create;
  jp.FOperation := joRightJoin;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.Select: ISelect;
begin
  Result := Self;
  Self.FQueryType := qtSelect;
end;

function TQueryBuilder.SelectFields: TSelectFields;
begin
  Result := FSelectFields;
end;

function TQueryBuilder.SelectFieldsSubqueries: TList<IQueryDetails>;
begin
  Result := FSelectFieldsSubqueries;
end;

function TQueryBuilder.SelectFields_Ordered: TFieldList;
begin
  Result := FSelectFields_Ordered;
end;

function TQueryBuilder.SetField(aField: TBaseField): IUpdateNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  if FUpdateFieldValues = nil then
    FUpdateFieldValues := TUpdateFieldValues.Create;
  if FUpdateFieldFields = nil then
    FUpdateFieldFields := TUpdateFieldFields.Create;
  FActiveUpdateField := aField;
  FActiveIncField    := nil;
end;

function TQueryBuilder.SetFieldWithValue(aField: TBaseField; const aValue: Variant): IInsert;
begin
  Result := Self;
  assert(FInsertFieldValues <> nil);

  FInsertFieldValues.AddOrSetValue(aField, aValue);
end;

function TQueryBuilder.SetFieldWithField(aField, aValueField: TBaseField): IInsert;
begin
  Result := Self;
  assert(FInsertFieldValues <> nil);
  Assert(not (aValueField is TCustomCalculatedField));
  Assert(not (aValueField is TNonQueryField));

  FInsertFieldFields.AddOrSetValue(aField, aValueField);
end;

function TQueryBuilder.From(aRecord: TDataRecord): IJoinNext;
begin
   Result := Self;
   FInsertFromRecord := aRecord;
end;

procedure TQueryBuilder.SetParentQuery(aParent: IQueryDetails);
begin
  FParentQuery := aParent;
end;

function TQueryBuilder.SubQuery(aSubQuery: IQueryBuilder): IJoin;
var jp: TJoinPartSubQuery;
begin
  Result := Self;
  jp := TJoinPartSubQuery.Create;
  jp.FOperation := joSubQuery;
  jp.FSubQuery  := aSubQuery as IQueryDetails;
  FJoinPartList.Add(jp);
end;

function TQueryBuilder.SubQueryField(aSubQuery: IQueryBuilder): ISelectNext;
begin
  Result := Self;
  if FSelectFieldsSubqueries = nil then
    FSelectFieldsSubqueries := TList<IQueryDetails>.Create;

  Assert((aSubQuery as IQueryDetails).SelectFields.Count = 1, 'subqueries in select may contain only 1 field');
  FSelectFieldsSubqueries.Add(aSubQuery as IQueryDetails);
end;

function TQueryBuilder.Sum(aField: TBaseField): ISelectNext;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;
  FSelectFields.Add(aField, soSum);
  FSelectFields_Ordered.Add(aField);
  DetermineAliasForField(aField);
end;

function TQueryBuilder.Table: string;
begin
  Result := FTable;
end;

function TQueryBuilder.TableHints: TTableHints;
begin
  Result := FTableHints;
end;

function TQueryBuilder.DoTopCount: Integer;
begin
  Result := FTopCount;
end;

function TQueryBuilder.TopCount(aRecords: Integer): ISelect;
begin
  Result := Self;
  FTopCount := aRecords;
end;

function TQueryBuilder.Update: IUpdate;
begin
  Result := Self;
  Self.FQueryType := qtUpdate;
end;

function TQueryBuilder.UpdateFieldFields: TUpdateFieldFields;
begin
   Result := FUpdateFieldFields;
end;

function TQueryBuilder.UpdateFieldValues: TUpdateFieldValues;
begin
  Result := FUpdateFieldValues;
end;

function TQueryBuilder.UpdateIncFieldFields: TUpdateFieldFields;
begin
   Result := FIncrementFieldFields;
end;

function TQueryBuilder.UpdateIncFieldValues: TUpdateFieldValues;
begin
  Result := FIncrementFieldValues;
end;

function TQueryBuilder.Where: IWhere;
begin
  Result := Self;
end;

function TQueryBuilder.WhereParts: TWherePartList;
begin
  Result := FWhereBuilder.FWhereParts;
end;

function TQueryBuilder.HavingParts: TWherePartList;
begin
  Result := FHavingBuilder.FWhereParts;
end;

function TQueryBuilder.WithJoinTableHints(aHints: TTableHints): IJoinNext;
begin
  Result := Self;
  Assert(FJoinPartList.Count > 0);
  Assert(FJoinPartList.Last is TJoinPartField);
  (FJoinPartList.Last as TJoinPartField).FTableHints :=
    (FJoinPartList.Last as TJoinPartField).FTableHints + aHints;
end;

function TQueryBuilder.WithTableHints(aHints: TTableHints): ISelectNext;
begin
  Result := Self;
  FTableHints := FTableHints + aHints;
end;

function TQueryBuilder.WithValue(const aValue: Variant): IUpdateEnd;
begin
  Result := Self;

  if FActiveIncField <> nil then
    FIncrementFieldValues.Add(FActiveIncField, aValue)
  else
    FUpdateFieldValues.Add(FActiveUpdateField, aValue);
end;

function TQueryBuilder.WithField(const aField: TBaseField): IUpdateEnd;
begin
  Result := Self;
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));

  if FActiveIncField <> nil then
    FIncrementFieldFields.Add(FActiveIncField, aField)
  else
    FUpdateFieldFields.Add(FActiveUpdateField, aField);
end;

function TQueryBuilder.GreaterOrEqual(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterOrEqual(aSubQuery);
end;

function TQueryBuilder.GreaterOrEqualField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterOrEqualField(aField);
end;

function TQueryBuilder.GreaterThan(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterThan(aSubQuery);
end;

function TQueryBuilder.GreaterThanField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.GreaterThanField(aField);
end;

function TQueryBuilder.LessOrEqual(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessOrEqual(aSubQuery);
end;

function TQueryBuilder.LessOrEqualField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessOrEqualField(aField);
end;

function TQueryBuilder.LessThan(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessThan(aSubQuery);
end;

function TQueryBuilder.LessThanField(const aField: TBaseField): IWhereEnd;
begin
  Result := Self;
  FWhereBuilder.LessThanField(aField);
end;

function TQueryBuilder.Having: IHaving;
begin
   Result := Self;
end;

function TQueryBuilder.FieldValue_(aField: TBaseField): IHavingNext;
begin
   Result := Self;
   FHavingBuilder.FieldValue(aField);
end;

function TQueryBuilder.Exists_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.Exists(aSubQuery);
end;

function TQueryBuilder.NotExists_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotExists(aSubQuery);
end;

function TQueryBuilder.DateBetween_(const BeginField, EindField: TBaseField; Datum: TDateTime): IHavingEnd;
begin
   Result := PointInTime_(BeginField, EindField, Datum, Datum);
end;

function TQueryBuilder.DateBetween_(const BeginField, EindField, DatumField: TBaseField): IHavingEnd;
begin
   Result := PointInTime_(BeginField, EindField, DatumField, DatumField);
end;

function TQueryBuilder.PointInTime_(const BeginField, EindField: TBaseField; BeginDatum, EindDatum: TDateTime): IHavingEnd;
begin
   Result := FieldValue_(BeginField).LessOrEqual_(BeginDatum)
      .AndHaving.OpenBracket_.FieldValue_(EindField).IsNull_.OrHaving.FieldValue_(EindField).GreaterOrEqual_(EindDatum).CloseBracket_;
end;

function TQueryBuilder.PointInTime_(const BeginField, EindField, BeginDatumField, EindDatumField: TBaseField): IHavingEnd;
begin
   Result := FieldValue_(BeginField).LessOrEqualField_(BeginDatumField)
      .AndHaving.OpenBracket_.FieldValue_(EindField).IsNull_.OrHaving.FieldValue_(EindField).GreaterOrEqualField_(EindDatumField).CloseBracket_;
end;

function TQueryBuilder.PointInTime_(const BeginField, EindField, BeginDatumField: TBaseField; EindDatum: TDateTime): IHavingEnd;
begin
   Result := FieldValue_(BeginField).LessOrEqualField_(BeginDatumField)
      .AndHaving.OpenBracket_.FieldValue_(EindField).IsNull_.OrHaving.FieldValue_(EindField).GreaterOrEqual_(EindDatum).CloseBracket_;
end;

function TQueryBuilder.PointInTime_(const BeginField, EindField: TBaseField; BeginDatum: TDateTime; EindDatumField: TBaseField): IHavingEnd;
begin
   Result := FieldValue_(BeginField).LessOrEqual_(BeginDatum)
      .AndHaving.OpenBracket_.FieldValue_(EindField).IsNull_.OrHaving.FieldValue_(EindField).GreaterOrEqualField_(EindDatumField).CloseBracket_;
end;

function TQueryBuilder.OpenBracket_: IHaving;
begin
   Result := Self;
   FHavingBuilder.OpenBracket;
end;

function TQueryBuilder.CloseBracket_: IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.CloseBracket;
end;

function TQueryBuilder.AndHaving: IHaving;
begin
   Result := Self;
   FHavingBuilder.AndWhere;
end;

function TQueryBuilder.OrHaving: IHaving;
begin
   Result := Self;
   FHavingBuilder.OrWhere;
end;

function TQueryBuilder.ISValue_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.ISValue(aValue);
end;

function TQueryBuilder.ISNotValue_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.ISNotValue(aValue);
end;

function TQueryBuilder.Equal_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.Equal(aValue);
end;

function TQueryBuilder.Equal_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.Equal(aSubQuery);
end;

function TQueryBuilder.NotEqual_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotEqual(aValue);
end;

function TQueryBuilder.NotEqual_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotEqual(aSubQuery);
end;

function TQueryBuilder.GreaterThan_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterThan(aValue);
end;

function TQueryBuilder.GreaterThan_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterThan(aSubQuery);
end;

function TQueryBuilder.GreaterOrEqual_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterOrEqual(aValue);
end;

function TQueryBuilder.GreaterOrEqual_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterOrEqual(aSubQuery);
end;

function TQueryBuilder.LessThan_ (const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessThan(aValue);
end;

function TQueryBuilder.LessThan_ (const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessThan(aSubQuery);
end;

function TQueryBuilder.LessOrEqual_(const aValue: Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessOrEqual(aValue);
end;

function TQueryBuilder.LessOrEqual_(const aSubQuery: IQueryBuilder): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessOrEqual(aSubQuery);
end;

function TQueryBuilder.Like_(const aValue: string): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.Like(aValue);
end;

function TQueryBuilder.InSet_ (const aSet: array of Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.InSet(aSet);
end;

function TQueryBuilder.InSet_(const aSet: array of Integer): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.InSet(aSet);
end;

function TQueryBuilder.InSet_(const aSet: array of string): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.InSet(aSet);
end;

function TQueryBuilder.NotInSet_(const aSet: array of Variant): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotInSet(aSet);
end;

function TQueryBuilder.NotInSet_(const aSet: array of Integer): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotInSet(aSet);
end;

function TQueryBuilder.NotInSet_(const aSet: array of string): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotInSet(aSet);
end;

function TQueryBuilder.NotLike(const aValue: string): IWhereEnd;
begin
   Result := Self;
   FWhereBuilder.NotLike(aValue);
end;

function TQueryBuilder.EqualField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.EqualField(aField);
end;

function TQueryBuilder.NotEqualField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.NotEqualField(aField);
end;

function TQueryBuilder.GreaterThanField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterThanField(aField);
end;

function TQueryBuilder.GreaterOrEqualField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.GreaterOrEqualField(aField);
end;

function TQueryBuilder.LessThanField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessThanField(aField);
end;

function TQueryBuilder.LessOrEqualField_(const aField: TBaseField): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.LessOrEqualField(aField);
end;

function TQueryBuilder.IsNull_(): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.IsNull;
end;

function TQueryBuilder.IsNotNull_(): IHavingEnd;
begin
   Result := Self;
   FHavingBuilder.IsNotNull;
end;

function TQueryBuilder.InSet(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
   Result := Self;
   FWhereBuilder.InSet(aSubQuery);
end;

function TQueryBuilder.NotInSet(const aSubQuery: IQueryBuilder): IWhereEnd;
begin
   Result := Self;
   FWhereBuilder.NotInSet(aSubQuery);
end;

{ TWherePartFieldValue }

procedure TWherePartFieldValue.AfterConstruction;
begin
  inherited;
  FOperation := woField;
  FFieldSelectType := soSelect;
end;

{ TWhereBuilder }

procedure TWhereBuilder.AfterConstruction;
begin
  inherited;
  FWhereParts   := TWherePartList.Create(True{owns});
  FActiveWhereOperation := soSelect;
end;

function TWhereBuilder.AndWhere: IWhere_Standalone;
var
  wp: TWherePart;
begin
  Result := Self;
  FActiveWhereField := nil;

  wp := TWherePart.Create;
  wp.FOperation := woAnd;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.CloseBracket: IWhere_Standalone;
var
  wp: TWherePart;
begin
  Result := Self;

  wp := TWherePart.Create;
  wp.FOperation := woCloseBracket;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.CompareToValue(const aType: TWhereCompare; const aValue: Variant): IWhere_Standalone;
var
  wp: TWherePartFieldValue;
begin
  Assert(aType in [wcEqual, wcEqualOrNull, wcNotEqual, wcIs, wcIsNot, wcGreater, wcGreaterEqual, wcLess, wcLessEqual, wcLike, wcNotLike]);
  Assert(FActiveWhereField <> nil);
  Result := Self;

  wp := TWherePartFieldValue.Create;
  wp.FField        := FActiveWhereField;
  wp.FCompare      := aType;
  wp.FCompareValue := aValue;
  wp.FFieldSelectType := FActiveWhereOperation;
  FWhereParts.Add(wp);
  //Reset to default
  FActiveWhereOperation := soSelect;
end;

function TWhereBuilder.Count: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soCount;
end;

function TWhereBuilder.CountDistinct: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soCountDistinct;
end;

function TWhereBuilder.Average: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soAvg;
end;

function TWhereBuilder.Max: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soMax;
end;

function TWhereBuilder.Min: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soMin;
end;

function TWhereBuilder.Sum: IWhere_Standalone;
begin
   Result := Self;
   FActiveWhereOperation := soSum;
end;

function TWhereBuilder.CompareToQuery(const aType: TWhereCompare; const aSubQuery: IQueryBuilder): IWhere_Standalone;
var
  wp: TWherePartFieldValue;
begin
  Assert(aType in [wcEqual, wcNotEqual, wcIs, wcIsNot, wcGreater, wcGreaterEqual, wcLess, wcLessEqual, wcLike, wcInQuerySet, wcNotInQuerySet]);
  Assert(FActiveWhereField <> nil);
  Result := Self;

  wp := TWherePartFieldValue.Create;
  wp.FField        := FActiveWhereField;
  wp.FCompare      := aType;
  wp.FCompareSubQuery := aSubQuery.Details;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.CompareToField(const aType: TWhereCompare; const aField: TBaseField): IWhere_Standalone;
var
  wp: TWherePartFieldField;
begin
  Assert(aType in [wcEqualField, wcNotEqualField, wcGreaterField, wcGreaterEqualField, wcLessField, wcLessEqualField]);
  Assert(FActiveWhereField <> nil);
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  Result := Self;

  wp := TWherePartFieldField.Create;
  wp.FField        := FActiveWhereField;
  wp.FCompare      := aType;
  wp.FCompareField := aField;
  wp.FFieldSelectType := FActiveWhereOperation;
  FWhereParts.Add(wp);
  //Reset to default
  FActiveWhereOperation := soSelect;
end;

destructor TWhereBuilder.Destroy;
begin
  FWhereParts.Free;
  inherited;
end;

function TWhereBuilder.Equal(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcEqual, aValue);
end;

function TWhereBuilder.Equal(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcEqual, aSubQuery);
end;

function TWhereBuilder.EqualField(const aField: TBaseField): IWhere_Standalone;
begin
  Result := CompareToField(wcEqualField, aField);
end;

function TWhereBuilder.EqualOrNull(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcEqualOrNull, aValue);
end;

function TWhereBuilder.Exists(const aSubQuery: IQueryBuilder): IWhere_Standalone;
var
  wp: TWherePartSubQuery;
begin
  Result := Self;
  FActiveWhereField := nil;

  wp := TWherePartSubQuery.Create;
  wp.FOperation := woExists;
  wp.FQuery     := aSubQuery;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.FieldValue(aField: TBaseField): IWhereNext_Standalone;
begin
  Assert(not (Afield is TCustomCalculatedField));
  Assert(not (Afield is TNonQueryField));
  FActiveWhereField := aField;
  Result := Self;
end;

function TWhereBuilder.GreaterOrEqual(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcGreaterEqual, aValue);
end;

function TWhereBuilder.GreaterThan(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcGreater, aValue);
end;

function TWhereBuilder.InSet(const aSet: array of Variant): IWhere_Standalone;
var
  wp: TWherePartFieldSet;
  i: Integer;
begin
  Assert(FActiveWhereField <> nil);
  Result := Self;

  wp := TWherePartFieldSet.Create;
  wp.FField        := FActiveWhereField;
  wp.FCompare      := wcInSet;
  SetLength(wp.FCompareSet, Length(aSet));
  for i := 0 to High(aSet) do
    wp.FCompareSet[i] := aSet[i];
  FWhereParts.Add(wp);
end;

function TWhereBuilder.ISNotValue(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcIsNot, aValue);
end;

function TWhereBuilder.IsNull(): IWhere_Standalone;
begin
  Result := CompareToValue(wcIs, null);
end;

function TWhereBuilder.InSet(const aSet: array of Integer): IWhere_Standalone;
var VariantArray: array of Variant;
    i: Integer;
begin
   SetLength(VariantArray, Length(aSet));
   for i := 0 to Length(aSet) -1 do
      VariantArray[i] := aSet[i];
   Result := InSet(VariantArray);
end;

function TWhereBuilder.InSet(const aSet: array of string): IWhere_Standalone;
var VariantArray: array of Variant;
    i: Integer;
begin
   SetLength(VariantArray, Length(aSet));
   for i := 0 to Length(aSet) -1 do
      VariantArray[i] := aSet[i];
   Result := InSet(VariantArray);
end;

function TWhereBuilder.InSet(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcInQuerySet, aSubQuery);
end;

function TWhereBuilder.IsNotNull(): IWhere_Standalone;
begin
  Result := CompareToValue(wcIsNot, null);
end;

function TWhereBuilder.ISValue(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcIs, aValue);
end;

function TWhereBuilder.LessOrEqual(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcLessEqual, aValue);
end;

function TWhereBuilder.LessThan(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcLess, aValue);
end;

function TWhereBuilder.Like(const aValue: string): IWhere_Standalone;
begin
  Result := CompareToValue(wcLike, aValue);
end;

function TWhereBuilder.NotEqual(const aValue: Variant): IWhere_Standalone;
begin
  Result := CompareToValue(wcNotEqual, aValue);
end;

function TWhereBuilder.NotEqual(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcNotEqual, aSubQuery);
end;

function TWhereBuilder.NotEqualField(const aField: TBaseField): IWhere_Standalone;
begin
   Result := CompareToField(wcNotEqualField, aField);
end;

function TWhereBuilder.NotExists(const aSubQuery: IQueryBuilder): IWhere_Standalone;
var
  wp: TWherePartSubQuery;
begin
  Result := Self;
  FActiveWhereField := nil;

  wp := TWherePartSubQuery.Create;
  wp.FOperation := woNotExists;
  wp.FQuery     := aSubQuery;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.NotInSet(const aSet: array of Variant): IWhere_Standalone;
var
  wp: TWherePartFieldSet;
  i: Integer;
begin
  Assert(FActiveWhereField <> nil);
  Result := Self;

  wp := TWherePartFieldSet.Create;
  wp.FField        := FActiveWhereField;
  wp.FCompare      := wcNotInSet;
  SetLength(wp.FCompareSet, Length(aSet));
  for i := 0 to High(aSet) do
    wp.FCompareSet[i] := aSet[i];
  FWhereParts.Add(wp);
end;

function TWhereBuilder.NotInSet(const aSet: array of Integer): IWhere_Standalone;
var VariantArray: array of Variant;
    i: Integer;
begin
   SetLength(VariantArray, Length(aSet));
   for i := 0 to Length(aSet) -1 do
      VariantArray[i] := aSet[i];
   Result := NotInSet(VariantArray);
end;

function TWhereBuilder.NotInSet(const aSet: array of string): IWhere_Standalone;
var VariantArray: array of Variant;
    i: Integer;
begin
   SetLength(VariantArray, Length(aSet));
   for i := 0 to Length(aSet) -1 do
      VariantArray[i] := aSet[i];
   Result := NotInSet(VariantArray);
end;

function TWhereBuilder.NotLike(const aValue: string): IWhere_Standalone;
begin
   CompareToValue(wcNotLike,aValue);
end;

function TWhereBuilder.OpenBracket: IWhere_Standalone;
var
  wp: TWherePart;
begin
  Result := Self;

  wp := TWherePart.Create;
  wp.FOperation := woOpenBracket;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.OrWhere: IWhere_Standalone;
var
  wp: TWherePart;
begin
  Result := Self;
  FActiveWhereField := nil;

  wp := TWherePart.Create;
  wp.FOperation := woOr;
  FWhereParts.Add(wp);
end;

function TWhereBuilder.WhereParts: TWherePartList;
begin
   Result := FWhereParts;
end;

function TWhereBuilder.GreaterOrEqual(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcGreaterEqual, aSubQuery);
end;

function TWhereBuilder.GreaterOrEqualField(const aField: TBaseField): IWhere_Standalone;
begin
   Result := CompareToField(wcGreaterEqualField, aField);
end;

function TWhereBuilder.GreaterThan(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcGreater, aSubQuery);
end;

function TWhereBuilder.GreaterThanField(const aField: TBaseField): IWhere_Standalone;
begin
   Result := CompareToField(wcGreaterField, aField);
end;

function TWhereBuilder.LessOrEqual(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcLessEqual, aSubQuery);
end;

function TWhereBuilder.LessOrEqualField(const aField: TBaseField): IWhere_Standalone;
begin
   Result := CompareToField(wcLessEqualField, aField);
end;

function TWhereBuilder.LessThan(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcLess, aSubQuery);
end;

function TWhereBuilder.LessThanField(const aField: TBaseField): IWhere_Standalone;
begin
   Result := CompareToField(wcLessField, aField);
end;

function TWhereBuilder.NotInSet(const aSubQuery: IQueryBuilder): IWhere_Standalone;
begin
   Result := CompareToQuery(wcNotInQuerySet, aSubQuery);
end;

{ TWherePartFieldSet }

procedure TWherePartFieldSet.AfterConstruction;
begin
  inherited;
  FOperation := woField;
  FFieldSelectType := soSelect;
end;

{ TWherePartFieldField }

procedure TWherePartFieldField.AfterConstruction;
begin
  inherited;
  FOperation := woField;
  FFieldSelectType := soSelect;
end;

{ TJoinPartFieldValue }

procedure TJoinPartFieldValue.AfterConstruction;
begin
  inherited;
  FOperation := joField;
end;

{ TJoinPartFieldSet }

procedure TJoinPartFieldSet.AfterConstruction;
begin
  inherited;
  FOperation := joField;
end;

{ TJoinPartFieldField }

procedure TJoinPartFieldField.AfterConstruction;
begin
  inherited;
  FOperation := joField;
end;

{ TJoinPartList }

function TJoinPartList.Fields: TFieldArray;
var  JoinPart: TJoinPart;
begin
   SetLength(Result, 0);
   for JoinPart in Self do
   begin
      if (JoinPart is TJoinPartFieldField) then
         AddFieldToArray((JoinPart as TJoinPartFieldField).FSourceField, Result);
      if (JoinPart is TJoinPartField) then
         AddFieldToArray((JoinPart as TJoinPartField).FJoinField, Result);
   end;
end;

function TJoinPartList.JoinFieldExist(aSourceField: TCustomField): Boolean;
var jp: TJoinPart;
begin
  Result := False;
  for jp in Self do
  begin
    //check if Join On Fields exists (not Join On Value?)
    if (jp is TJoinPartFieldField) and
       ( (jp as TJoinPartFieldField).FSourceField = aSourceField) then
      Exit(True);
  end;
end;

{ TBaseFieldValues }

function TBaseFieldValues.GetFieldByName(const aFieldName: string): TBaseField;
var f: TBaseField;
begin
  Result := nil;
  for f in Self.Keys do
  begin
    if SameText(f.FieldName, aFieldName) then
      Exit(f);
  end;
end;


{ TBaseFieldFields }

function TBaseFieldFields.GetFieldByName(const aFieldName: string): TBaseField;
var f: TBaseField;
begin
  Result := nil;
  for f in Self.Keys do
  begin
    if SameText(f.FieldName, aFieldName) then
      Exit(f);
  end;
end;

{ TWherePartList }

function TWherePartList.Fields: TFieldArray;
var  WherePart: TWherePart;
begin
   SetLength(Result, 0);
   for WherePart in Self do
   begin
      if (WherePart.FOperation <> woField) then
         Continue;

      if (WherePart is TWherePartField) then
         AddFieldToArray((WherePart as TWherePartField).FField, Result);
      if WherePart is TWherePartFieldField then
         AddFieldToArray((WherePart as TWherePartFieldField).FCompareField, Result)
   end;
end;

end.
