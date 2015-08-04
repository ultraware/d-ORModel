unit Test.DataRecord;

interface

uses
  Classes,
  TestFramework, Meta.Data, Meta.CustomIDTypes, Data.EnumField;

type
  TDataRecordTester = class(TTestCase)
  protected
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestTypeConversion;
    procedure TestEmptyNullValues;
    procedure TestChanges;
    procedure TestValidation;
    procedure TestPropertyChanges;

    //procedure TestDefaultValues;
    procedure TestFKTypes;
    procedure TestEnum;

    procedure TestAutoJoin;
    procedure TestAliasForCombiModel;

    procedure TestCalculatedFields;
    procedure TestArrayAppend;
  end;

implementation

uses
  Data.DataRecord, Variants, SysUtils, GlobalRTTI, Rtti, TypInfo, Data.Query,
  Data.CustomTypes, MWUtils, Test.CRUD, CRUD.Test;

type
  TFK1 = type TBaseIDValue;
  TFK2 = type TBaseIDValue;

type

  //TFK1 = type Int64;
  TTypedFK1Field = class(TCustomIDField<TFK1>);
  //TFK2 = type Int64;
  TTypedFK2Field = class(TCustomIDField<TFK2>);

  TMyIDField = class(TBaseIDField)
  public
    //property FieldValue;
  end;

  TMyEnum      = (meNone, meAvalue, meBvalue, meCvalue);
  TMyEnumField = class(TTypedStringEnumField<TMyEnum>)
  protected
    function  ConvertStringToEnum(const aValue: string): TMyEnum;
    function  ConvertEnumToString(const aEnum: TMyEnum): string;
    class function ConvertEnumToVariant(const aEnum: TMyEnum): Variant; override;
    class function ConvertEnumToDisplayString(const aEnum: TMyEnum): string; override;
    class function ConvertVariantToEnum(const aValue: Variant): TMyEnum; override;
  end;
  const C_MyEnum: array[TMyEnum] of string = ('leeg', 'A', 'B', 'C');

type
  TTestModel = class(TDataRecord)
  private
    function GetTypedFK1Field(const Index: Integer): TTypedFK1Field;
    function GetTypedFK2Field(const Index: Integer): TTypedFK2Field;
    function GetMyIDField(const Index: Integer): TMyIDField;
//    function GetTypedGegeven_IDField(const Index: Integer): TTypedGegeven_IDField;
    function GetMyEnumField(const Index: Integer): TMyEnumField;
  public
    [TTypedMetaField   ('ID', ftFieldID, True{required}, '')]
    property  ID      : TMyIDField         index  0   read GetMyIDField;
    [TTypedMetaField   ('Name', ftFieldString, True{required}, '')]
    property  Name    : TTypedStringField     index  1   read GetStringField;
    [TTypedMetaField   ('DateTime', ftFieldDateTime, True{required}, '')]
    property  DateTime: TTypedDateTimeField   index  2   read GetDateTimeField;

//    property  FK1: TTypedFK1Field   index  3  read GetTypedField<TTypedFK1Field>;
//    property  FK2: TTypedFK2Field   index  4  read GetTypedField<TTypedFK2Field>;

    property  FK1: TTypedFK1Field   index  3  read GetTypedFK1Field;
    property  FK2: TTypedFK2Field   index  4  read GetTypedFK2Field;

//    property  Gegeven_ID: TTypedGegeven_IDField index 5 read GetTypedGegeven_IDField;

    property  MyEnum: TMyEnumField index 5 read GetMyEnumField;
    [TTypedMetaField   ('TestEnum', ftFieldString, False, '')]
    property  MyEnum2: TMyEnumField index 5 read GetMyEnumField;
    [TTypedMetaField   ('TestEnum2', ftFieldInteger, False, '')]
    property  MyEnum3: TMyEnumField index 6 read GetMyEnumField;

//    [TTypedMetaField   ('MyEmailAdres', ftFieldString, False, '')]
//    property MyEmailAdres: TTypedEmailField index 9 read GetTypedEmailField;
//    [TTypedMetaField   ('MyBTWNummer', ftFieldString, False, '')]
//    property MyBTWNummer: TTypedBTWNummerField index 10 read GetTypedBTWNummerField;
  end;

  TCalcModel = class(TDataRecord)
  public
    procedure AfterConstruction; override;

    property Aantal     : TTypedIntegerField      index  0   read GetIntegerField;
    property AantalKeer2: TTypedIntegerCalcField  index  1   read GetTypedIntegerCalcField;
  end;

//  StamRegio = class(Stam);

  TRelatieModel = class(TDataRecord)
  public
//    [Relatie_T(Meta.Relatie_T.ID)]     property  ID_Relatie_T               : TTypedRelatie_T_IDField      index 0 read GetTypedRelatie_T_IDField;
//    [Relatie_T(RelatieStam_ID)]        property  Relatie_T_RelatieStam_ID   : TTypedRelatieStam_IDField    index 1 read GetTypedRelatieStam_IDField;
//    [Relatie_T(StamRegio_ID)]          property  Relatie_T_StamRegio_ID     : TTypedStam_IDField           index 2 read GetTypedStam_IDField;
//    {RelatieStam}
//    [RelatieStam(Meta.RelatieStam.ID)] property  ID_RelatieStam             :  TTypedRelatieStam_IDField   index 3 read GetTypedRelatieStam_IDField;
//    [RelatieStam(Persoon)]             property  Persoon                    :  TTypedIntegerField          index 4 read GetIntegerField;
//
//    [StamRegio(ID)]                    property  ID_StamRegio               : TTypedStam_IDField         index   5 read GetTypedStam_IDField;
//    [StamRegio(StamSoort_ID)]          property  StamRegio_StamSoort_ID     : TTypedStamSoort_IDField    index   6 read GetTypedStamSoort_IDField;
//    [StamRegio(Omschrijving)]          property  StamRegio_Omschrijving     : TTypedStringField          index   7 read GetStringField;
//    [StamRegio(Code)]                  property  StamRegio_Code             : TTypedStringField          index   8 read GetStringField;
  end;

{ TDataRecordTester }

procedure TDataRecordTester.SetUp;
begin
  inherited;
end;

procedure TDataRecordTester.TearDown;
begin
  inherited;
end;

procedure TDataRecordTester.TestEmptyNullValues;
var
  tm: TTestModel;
begin
  tm := TTestModel.Create;
  try
    Check(tm.ID.IsEmpty, 'Field must be default empty');
    Check(tm.Name.IsEmpty, 'Field must be default empty');

    //'' as string must become null
    tm.Name.TypedString := '';
    Check(tm.Name.IsNull, 'empty string must become null');
    //0 as datetime must become null
    tm.DateTime.TypedDateTime := 0;
    Check(tm.Name.IsNull, 'empty datetime must become null');
  finally
    tm.Free;
  end;
end;

procedure TDataRecordTester.TestEnum;
var
  tm: TTestModel;
begin
  tm := TTestModel.Create;
  try
    //no metadata, auto string type
    tm.MyEnum.TypedEnum := meAvalue;
    CheckEquals(C_MyEnum[meAvalue], tm.MyEnum.ValueAsString);

    //with metadata = string type
    tm.MyEnum2.TypedEnum := meAvalue;
    CheckEquals(C_MyEnum[meAvalue], tm.MyEnum2.ValueAsString);

    try
      //with metadata = integer type
      tm.MyEnum3.TypedEnum := meAvalue;
      Check(False, 'should raise exception');
    except
      Check(True, 'should raise exception');
    end;
    CheckEquals(Ord(meNone), Ord(tm.MyEnum3.TypedEnum));
  finally
    tm.Free;
  end;
end;

procedure TDataRecordTester.TestFKTypes;
var
  tm: TTestModel;
begin
  tm := TTestModel.Create;
  try
//    tm.FK1.TypedID := tm.FK2.TypedID;   //should not compile
  finally
    tm.Free;
  end;
end;

procedure TDataRecordTester.TestPropertyChanges;
var
  temp: TTESTCRUD;
begin
  temp := TTESTCRUD.Create;
  try
    temp.Data.Tekst.DisplayLabel := 'my' + temp.Data.Tekst.DisplayLabel;
    CheckEquals('my' + TESTCRUD.Data.Tekst.DisplayLabel, temp.Data.Tekst.DisplayLabel);
    temp.Data.Tekst.MaxValue   := temp.Data.Tekst.MaxValue + 1;
    temp.Data.Tekst.IsRequired   := not temp.Data.Tekst.IsRequired;

    //check: changes on the fly should only be done for the actual object, but
    //should not change the global metadata!
    CheckNotEquals(TESTCRUD.Data.Tekst.DisplayLabel, temp.Data.Tekst.DisplayLabel);
    CheckNotEquals(TESTCRUD.Data.Tekst.MaxValue, temp.Data.Tekst.MaxValue);
    CheckNotEquals(TESTCRUD.Data.Tekst.IsRequired, temp.Data.Tekst.IsRequired);
  finally
    temp.Free;
  end;
end;

procedure TDataRecordTester.TestTypeConversion;
var
   tm: TTestModel;
begin
   tm := TTestModel.Create;
   try
      tm.ID.ValueAsVariant := 123;
      tm.ID.ValueAsVariant := '123';
      tm.ID.ValueAsVariant := 123.456;
      CheckEquals(123, tm.ID.TypedIDValue, 'should be truncated');
      try
      tm.ID.ValueAsString := 'notanumber';
      Check(False, 'should raise exception');
      except
      Check(True, 'should raise exception');
      end;

      tm.Name.ValueAsInteger := 123;
      CheckEquals('123', tm.Name.ValueAsString, 'should be same');
      tm.Name.ValueAsString := '123';
      CheckEquals('123', tm.Name.TypedString, 'should be same');
      tm.Name.ValueAsDouble := 123.456;
      CheckEquals(FloatToStr(123.456), tm.Name.ValueAsString, 'should be same');
      CheckEquals(123.456, tm.Name.ValueAsDouble, 0.001, 'should be same');
   finally
      tm.Free;
   end;
end;

procedure TDataRecordTester.TestValidation;
var
   tm: TTestModel;
begin
   tm := TTestModel.Create;
   try
      Check(tm.ID.IsEmpty, 'Field must be default empty');
      Check(tm.Name.IsEmpty, 'Field must be default empty');

      Check(tm.ID.IsValid, 'empty required ID field is valid');
      Check(tm.Name.IsRequired, 'name field is required');
      Check(not tm.Name.IsValid, 'empty required field is NOT valid');

      tm.ID.ValueAsString := '123';
      Check(tm.ID.IsValid, 'filled required field is valid');
      //'' as string must become null
      tm.ID.ValueAsString := '';
      Check(tm.ID.IsValid, 'empty required ID field is valid');

      tm.Name.ValueAsString := 'test';
      Check(tm.Name.IsValid, 'filled required field is valid');
      //'' as string must become null
      tm.Name.TypedString := '';
      Check(not tm.Name.IsValid, 'empty required field is NOT valid');

      tm.Clear2Empty;
      Check( tm.IsValid(True {skip empty fields}), 'partial filled update should be possible');
      tm.ID.ValueAsInt64 := 123;
      tm.DateTime.TypedDateTime := Now;
      Check( tm.IsValid(True {skip empty fields}), 'partial filled update should be possible');
      tm.Name.TypedString := 'test';
      Check( tm.IsValid(True {skip empty fields}), 'partial filled update should be possible');
      Check( tm.IsValid(False {check all fields}), 'partial filled update should be possible');

      tm.Name.MaxValue := 1;
      Check(Length(tm.Name.TypedString) > 1, 'Test name should be longer than 1');
      CheckFalse(tm.IsValid(), 'Name is longer than maximum length');






      {Emailadres checks}
//      tm.MyEmailAdres.TypedString := 'test@email.nl';
//      CheckEquals(True, tm.MyEmailAdres.IsValid, 'Emailadres voldoet aan de eisen');
//      tm.MyEmailAdres.TypedString := 'test@@ema@il@.';
//      CheckEquals(False, tm.MyEmailAdres.IsValid, 'Emailadres voldoet niet aan de eisen');
//      tm.MyEmailAdres.TypedString := '@email.nl';
//      CheckEquals(False, tm.MyEmailAdres.IsValid, 'Emailadres voldoet niet aan de eisen');
//      tm.MyEmailAdres.TypedString := '';
//      CheckEquals(True, tm.MyEmailAdres.IsValid, 'Emailadres is leeg maar niet verplicht mag daarom leeg zijn');
//
//      {BTWNummer checks}
//      tm.MyBTWNummer.TypedString := 'NL 8132.73.018.B.01';
//      CheckEquals(True, tm.MyBTWNummer.IsValid, 'BTWnummer voldoet aan de regels.');
//      tm.MyBTWNummer.TypedString := 'DE 129273398'; //BTW nummer BMW DE
//      CheckEquals(True, tm.MyBTWNummer.IsValid, 'BTWnummer voldoet aan de regels.');
//      tm.MyBTWNummer.TypedString := 'BE 0478.339.860'; //BTW nummer MM BE
//      CheckEquals(True, tm.MyBTWNummer.IsValid, 'BTWnummer voldoet aan de regels.');
//
//      tm.MyBTWNummer.TypedString := 'NL 8132.73.018.B.0';
//      CheckEquals(False, tm.MyBTWNummer.IsValid, 'BTWnummer voldoet niet aan de regels.');
//      tm.MyBTWNummer.TypedString := 'BE 0478.339.8600';
//      CheckEquals(False, tm.MyBTWNummer.IsValid, 'BTWnummer voldoet niet aan de regels.');
   finally
      tm.Free;
   end;
end;

{
type
  TCombinedFormatAttribute = class(TCustomAttribute)
  public
    constructor Create(const aFormat: string; aField1: TBaseTableFieldClass);overload;
    constructor Create(const aFormat: string; aField1: TBaseTableFieldClass; aField2: TBaseTableFieldClass);overload;
    constructor Create(const aFormat: string; aField1: TBaseTableFieldClass; aField2: TBaseTableFieldClass; aField3: TBaseTableFieldClass);overload;
    constructor Create(const aFormat: string; aField1: TBaseTableFieldClass; aField2: TBaseTableFieldClass; aField3: TBaseTableFieldClass; aField4: TBaseTableFieldClass);overload;
  end;
  }
  //todo: make string calc field, runtime propertyname genereren (bijv AdresJoin2_Woonplaats)
  //combined
  //[TMetaAttribute('%s: %s - %s', Meta.Gegeven.ID, Meta.Gegeven.WebDB, Meta.Gegeven.Bron) ]

procedure TDataRecordTester.TestAliasForCombiModel;
//var
//   relatie: TRelatieModel;
//   query: IQueryBuilder;
begin
//   relatie := TRelatieModel.Create;
//   try
//      query := TQueryBuilder.Create(relatie.ID_Relatie_T);
//      query.Select.AllFieldsOf(relatie)
//         .InnerJoin.OnFields(relatie.ID_RelatieStam, relatie.Relatie_T_RelatieStam_ID)
//         .InnerJoin.OnFields(relatie.ID_StamRegio  , relatie.Relatie_T_StamRegio_ID);
//
////      if TDataProvider.QuerySearchSingle(query as IQueryDetails) then ;
//
//
//   finally
//      relatie.Free;
//   end;
  Check(false);
end;

procedure TDataRecordTester.TestAutoJoin;
begin
//  model maken (evt met groepen?)
//  dan zelf custom de joins maken (subqueries)
//  uitzoeken: combinded format velden in TADOQuery?
  Check(false);
end;

procedure TDataRecordTester.TestCalculatedFields;
var
  cm: TCalcModel;
begin
  cm := TCalcModel.Create;
  try
    cm.Aantal.TypedInteger := 1;
    CheckEquals(2, cm.AantalKeer2.TypedInteger);
  finally
    cm.Free;
  end;
end;

procedure TDataRecordTester.TestChanges;
var
  tm: TTestModel;
begin
  tm := TTestModel.Create;
  try
    Check(tm.ID.IsEmpty, 'must be default empty');
    Check( tm.ID.OrigFieldValue = Unassigned, 'origvalue must be default empty');
    Check( not tm.ID.IsModified, 'default not modified');
    Check( not tm.IsModified, 'default not modified');

    tm.ID.ValueAsInteger := 10;
    CheckEquals(10, tm.ID.TypedIDValue, 'must have our set value');
    Check( not tm.ID.IsEmpty, 'must have value, not empty anymore');
    Check( tm.ID.OrigFieldValue = Unassigned, 'origvalue must be still empty because it is first value after "empty"');
    Check( tm.ID.IsModified, 'it is modified');
    Check( tm.IsModified, 'it is modified');

    tm.UndoChanges;
    Check(tm.ID.IsEmpty, 'must have original value again');
    Check( not tm.ID.IsModified, 'not modified after undo');
    Check( not tm.IsModified, 'not modified after undo');

    tm.ID.ValueAsInteger := 10;
    Check( tm.ID.IsModified, 'it is modified');
    CheckEquals(10, tm.ID.TypedIDValue, 'must have our set value');
    Check( tm.ID.OrigFieldValue = Unassigned, 'origvalue must be still empty because it is first value after "empty"');
    tm.ID.ValueAsInteger := 20;
    CheckEquals(20, tm.ID.TypedIDValue, 'must have our set value');
    Check( tm.ID.OrigFieldValue = 10, 'origvalue have first "real" value');
    tm.ID.ValueAsInteger := 30;
    CheckEquals(30, tm.ID.TypedIDValue, 'must have our set value');
    Check( tm.ID.OrigFieldValue = 10, 'origvalue have first "real" value, not previous value');

    tm.UndoChanges;
    CheckEquals(10, tm.ID.TypedIDValue, 'must first "real" value');
    Check( not tm.ID.IsModified, 'not modified after undo');
  finally
    tm.Free;
  end;
end;

procedure TDataRecordTester.TestArrayAppend;
var
   left, right: TValidationErrors;
   LeftLength, RightLength: Integer;
   SLeft0, SRight0, SRight1: string;
begin
   LeftLength := 1;
   RightLength := 2;
   SLeft0 := 'Left0';
   SRight0 := 'Right0';
   SRight1 := 'Right1';

   SetLength(left, LeftLength);
   SetLength(Right, RightLength);

   left[0].Error := SLeft0;

   right[0].Error := SRight0;
   right[1].Error := SRight1;

   AppendValidationArray(left, right);
   CheckEquals(SLeft0, left[0].Error);
   CheckEquals(left[1].Error, right[0].Error);
   CheckEquals(left[2].Error, right[1].Error);
   CheckEquals(LeftLength+RightLength, Length(left));

   left := nil;
   right := nil;
   CheckEquals(0, Length(left));
   CheckEquals(0, Length(right));
   AppendValidationArray(left, right);
   CheckEquals(0, Length(left));

   SetLength(right, RightLength);
   right[0].Error := SRight0;
   right[1].Error := SRight1;
   AppendValidationArray(left, right);
   CheckEquals(RightLength, Length(left));
   CheckEquals(left[0].Error, right[0].Error);
   CheckEquals(left[1].Error, right[1].Error);
end;

{ TTypedFK1Field }

//function TTypedFK1Field.GetTypedID: TFK1;
//begin
//  if IsNull then
//    Result.ID := 0
//  else
//    Result.ID := FieldValue;
//end;

{ TTypedFK2Field }

//function TTypedFK2Field.GetTypedID: TFK2;
//begin
//  if IsNull then
//    Result.ID := 0
//  else
//    Result.ID := FieldValue;
//end;

{ TTestModel }

function TTestModel.GetMyEnumField(const Index: Integer): TMyEnumField;
begin
  Result := Self.Items[Index] as TMyEnumField;
end;

function TTestModel.GetMyIDField(const Index: Integer): TMyIDField;
begin
  Result := Self.Items[Index] as TMyIDField;
end;

function TTestModel.GetTypedFK1Field(const Index: Integer): TTypedFK1Field;
begin
  Result := Self.Items[Index] as TTypedFK1Field;
end;

function TTestModel.GetTypedFK2Field(const Index: Integer): TTypedFK2Field;
begin
  Result := Self.Items[Index] as TTypedFK2Field;
end;

{ TMyEnumField }

class function TMyEnumField.ConvertEnumToDisplayString(
  const aEnum: TMyEnum): string;
begin
  Result := C_MyEnum[aEnum];
end;

function TMyEnumField.ConvertEnumToString(const aEnum: TMyEnum): string;
begin
  Result := C_MyEnum[aEnum];
end;

class function TMyEnumField.ConvertEnumToVariant(const aEnum: TMyEnum): Variant;
begin
  //Result := Ord(aEnum);
  Result := C_MyEnum[aEnum];
end;

function TMyEnumField.ConvertStringToEnum(const aValue: string): TMyEnum;
var e: TMyEnum;
begin
  Result := meNone;
  for e := Low(C_MyEnum) to High(C_MyEnum) do
    if C_MyEnum[e] = aValue then
      Exit(e);
end;

class function TMyEnumField.ConvertVariantToEnum(
  const aValue: Variant): TMyEnum;
var e: TMyEnum;
begin
  Result := meNone;

  if VarIsOrdinal(aValue) then
    Result := TMyEnum(Integer(aValue))
  else
    for e := Low(C_MyEnum) to High(C_MyEnum) do
      if String(C_MyEnum[e]) = aValue then
        Exit(e);
end;

{ TCalcModel }

procedure TCalcModel.AfterConstruction;
begin
  inherited;
  Self.AantalKeer2.OnCalcValue :=
    function(aRow: TDataRecord): Integer
    begin
      with TCalcModel(aRow) do             //use aRow in lists!
        Result := Aantal.TypedInteger * 2;
    end;
end;

end.


