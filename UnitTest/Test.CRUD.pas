unit Test.CRUD;

interface

uses
  Classes, Types,
  TestFramework, Data.DataRecord, Data.CRUD;

type
  TCRUDTester = class(TTestCase)
  protected
    class var FTablesChecked: Boolean;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestThreadFinalization;
    procedure TestCreateRecord;
    procedure TestRetrieveRecord;
    procedure TestUpdateRecord;
    procedure TestDeleteRecord;

    procedure TestDefaultValues;
    procedure TestSQLQueries;
    procedure TestJoinAliases;
    procedure TestWhereParameter;
    procedure TestCRUDConstraints;
    procedure TestTableHints;
    procedure TestFindQuery;

    procedure TestDoorJoinen;

    procedure TestTDataset;
    procedure TestTDatasetPropertyDisplaylabel;
    procedure TestTDatasetUniquename;

    procedure TestCRUDless;
  end;

   TTempCRUD = class(TDataCRUD<TDataRecord>);

implementation

uses
  CRUD.TEST, SysUtils, DateUtils,
  Data.CRUDDataset,
  DB, DBGrids, Forms,
  Meta.CustomIDTypes, Variants, Data.Query,
  Meta.Data, ThreadFinalization, Meta.TEST, DB.SQLBuilder, DB.Connection, DB.ConnectionPool,
  DB.Connection.SQLServer, Data.Base, System.Diagnostics, Vcl.Dialogs,
  Data.Win.ADODB;

{ TCRUDTester }

procedure TCRUDTester.SetUp;
var
  connection: TBaseConnection;
  str: TStringList;
  sql: string;
begin
  inherited;

  if not FTablesChecked then
  begin
    connection := TDBConnectionPool.GetConnectionFromPool(TESTCRUD.GetProvider.GetDBSettings);
    str := TStringList.Create;
    try
      if (oconnection as TBaseADOConnection).IsSQLServerCE then
      begin
        //strange, does not work with SQL CE
        with TADOCommand.Create(nil) do
        try
          ConnectionString := (oconnection as TBaseADOConnection).ADOConnection.ConnectionString;
          CommandText := 'SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES';
          recordset := Execute;
          while not recordset.EOF do
          begin
            str.Add( recordset.Fields[0].Value );
            recordset.MoveNext;
          end;
        finally
          Free;
        end
      end
      else
        (oconnection as TBaseADOConnection).ADOConnection.GetTableNames(str);

      str.Text := UpperCase(str.Text);
      if str.IndexOf(UpperCase(TESTCRUD.IDField.TableName)) < 0 then
      begin
        sql := TSQLBuilder.GenerateCreateTableSQL(TESTCRUD.Data, True);
        (connection as TBaseADOConnection).DirectExecute(sql);
      end;

      FTablesChecked := True;
    finally
      str.free;
      TDBConnectionPool.PutConnectionToPool(TESTCRUD.GetProvider.GetDBSettings, connection);
    end;
  end;
end;

procedure TCRUDTester.TearDown;
begin
  inherited;
end;

procedure TCRUDTester.TestCreateRecord;
var
  dt: TDateTime;
begin
  TESTCRUD.ClearAll;
  TESTCRUD.Data.Tekst.TypedString := 'TestCreateRecord';
  dt := Now;
  dt := RecodeSecond(dt, 0);
  dt := RecodeMilliSecond(dt, 0); //seconds + ms gets trucated by SQL Server
  TESTCRUD.Data.Datum.TypedDateTime := dt;
  TESTCRUD.RecordCreate;

  CheckFalse(TESTCRUD.Data.ID.IsEmptyOrNull, 'ID value should be fetched after insert');

  TESTCRUD.RecordRetrieve(TESTCRUD.Data.ID.TypedID.ID);
  CheckEqualsString('TestCreateRecord', TESTCRUD.Data.Tekst.TypedString);
  CheckEqualsString(DateTimeToStr(dt), DateTimeToStr(TESTCRUD.Data.Datum.TypedDateTime));
end;

type
  TBaseField_Ext = class(TBaseField);

procedure TCRUDTester.TestCRUDConstraints;
var
  tablefieldmeta {, tablefieldmetaFK}: TBaseTableAttribute;
  errors: TValidationErrors;
begin
  tablefieldmeta := TBaseField_Ext(TESTCRUD.Data.Tekst).MetaField;
  //same table/field constraint, validation can be done locally/clientside
  tablefieldmeta.ConstraintMeta :=
    TFieldConstraintMeta.Create( tablefieldmeta,
                                 TStringDynArray.Create('test', 'test2') );
  try
    TESTCRUD.ClearAll;
    TESTCRUD.Data.Tekst.TypedString := 'test3';

    errors := TESTCRUD.DoFullValidation(True);
    CheckEquals(1, Length(errors), 'one error because of value "test3"');

    try
      TESTCRUD.RecordCreate;
      Check(False, 'Should raise error');
    except
      Check(True, 'should raise constraint error');
    end;
  finally
    tablefieldmeta.ConstraintMeta.Free;
    tablefieldmeta.ConstraintMeta := nil;
  end;

//  tablefieldmeta   := TBaseField_Ext(Relatie_TCRUD.Data.RelatieStam_ID).MetaField;
//  tablefieldmetaFK := TBaseField_Ext(RelatieStamCRUD.Data.Persoon).MetaField;
//  //other table/field constraint, validation must be done on server
//  tablefieldmeta.ConstraintMeta :=
//    TFieldConstraintMeta.Create( tablefieldmetaFK,
//                                 TStringDynArray.Create('1') );  //must be Persoon=1
//  try
//    // dbo.RelatieStam AS rs LEFT OUTER JOIN
//    // dbo.Relatie_T AS r ON rs.ID = r.RelatieStam_ID LEFT OUTER JOIN
//    //CASE WHEN rs.Persoon = 1 THEN CASE WHEN rs.Medewerker_Relatie_T_ID = r.ID THEN 'M' WHEN sg.Handvat = 'Relatie Type_Gerelateerd' THEN 'G'
//    //WHEN r.Relatie_ID > 0 THEN 'C' ELSE 'N' END ELSE 'O' END AS RelatieState,
//
//    Relatie_TCRUD.NewQuery
//      .Select.Fields([Relatie_TCRUD.Data.ID, Relatie_TCRUD.Data.RelatieStam_ID]);
//    Check(Relatie_TCRUD.QuerySearchSingle, 'no relatie_T record?');
//    RelatieStamCRUD.NewQuery
//      .Select.Fields([RelatieStamCRUD.Data.ID])
//      .Where.FieldValue(RelatieStamCRUD.Data.Persoon).NotEqual(1);
//    Check(RelatieStamCRUD.QuerySearchSingle, 'no relatiestam record?');
//
//    Relatie_TCRUD.Data.RelatieStam_ID.TypedID := RelatieStamCRUD.Data.ID.TypedID;
//    try
//      Relatie_TCRUD.RecordUpdate;
//      Check(False, 'Should raise error');
//    except
//      Check(True, 'should raise constraint error');
//    end;
//  finally
//    tablefieldmeta.ConstraintMeta.Free;
//    tablefieldmeta.ConstraintMeta := nil;
//  end;
//



end;

procedure TCRUDTester.TestCRUDless;
var
  t: TTEST;
  td: TDataRecord;
begin
  t := TTEST.Create();
  try
    t.Tekst.TypedString := 'test';
  finally
    t.Free;
  end;

  td := TDataRecord.Create();
  try
    td.Add( TTypedStringField.Create()  );
    td.Add( TTypedIntegerField.Create() );

    td.Fields[0].ValueAsString  := 'test';
    td.Fields[0].ValueAsInteger := 0;
  finally
    td.Free;
  end;
end;

procedure TCRUDTester.TestDefaultValues;
//var ID: Integer;
begin
   TESTCRUD.Data.Clear2EmptyOrDefault;
   TESTCRUD.Data.Tekst.TypedString := 'Tekst';
   if not TESTCRUD.Data.Datum.HasDefaultValue then
     Assert(False, 'Testcase voor default values werkt niet meer');
   TESTCRUD.RecordCreate;
   {$MESSAGE HINT 'todo: andere tabel voor default value test gebruiken'}
   {
   CheckEquals(True, TESTCRUD.Data.DefaultTekst.HasDefaultValue);
   TESTCRUD.RecordCreate;
   ID := TESTCRUD.Data.ID.TypedID.ID;
   TESTCRUD.Data.Clear2Empty;
   CheckEquals(True, TESTCRUD.Data.DefaultTekst.IsEmpty, 'Testcruddata moet leeg zijn.');

   TESTCRUD.RecordRetrieve(ID);
   CheckEquals(TESTCRUD.Data.DefaultTekst.DefaultValue, TESTCRUD.Data.DefaultTekst.TypedString, 'Waarde moet gelijk zijn aan de defaultwaarde');

   TESTCRUD.Data.DefaultTekst.TypedString := 'Niet de defaultekst';
   TESTCRUD.RecordUpdate;
   TESTCRUD.Data.Clear2Null;
   TESTCRUD.RecordRetrieve(ID);
   CheckEquals('Niet de defaultekst', TESTCRUD.Data.DefaultTekst.TypedString, 'Waarde mag niet gelijk zijn aan de defaultwaarde');
   TESTCRUD.Data.DefaultTekst.Clear2Null;
   TESTCRUD.RecordUpdate;
   TESTCRUD.Data.Clear2Null;
   TESTCRUD.RecordRetrieve(ID);
   CheckEquals(TESTCRUD.Data.DefaultTekst.DefaultValue, TESTCRUD.Data.DefaultTekst.TypedString, 'Waarde moet gelijk zijn aan de defaultwaarde');
   }
end;

procedure TCRUDTester.TestDeleteRecord;
var
  id: integer;
begin
  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID]);
  Check( TESTCRUD.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  id := TESTCRUD.Data.ID.TypedID.ID;

  //delete
  TESTCRUD.RecordDelete;

  TESTCRUD.NewQuery
    .Select.Fields   ([TESTCRUD.Data.ID])
    .Where.FieldValue(TESTCRUD.Data.ID)
          .Equal     (id);
  CheckFalse( TESTCRUD.QuerySearchSingle, 'record must have been deleted' );
end;

procedure TCRUDTester.TestDoorJoinen;
begin
  {
  Bedrijf_TCRUD.NewQuery
    .Select.Fields([Bedrijf_TCRUD.Data.ID,
                    Bedrijf_TCRUD.Data.HoofdContactPersoon.Telefoon]);
  Bedrijf_TCRUD.QuerySearchSingle;
  Bedrijf_TCRUD.Data.ID.TypedIDValue;
  Bedrijf_TCRUD.Data.HoofdContactPersoon.Telefoon.TypedString;
  if Bedrijf_TCRUD.Data.HoofdContactPersoon.Mobiel.IsEmptyOrNull then
    Bedrijf_TCRUD.Fetch([Bedrijf_TCRUD.Data.HoofdContactPersoon.Mobiel,
                         Bedrijf_TCRUD.Data.StamBranche.Omschrijving,
                         Bedrijf_TCRUD.Data.StamRechtsvorm.Omschrijving,
                         Bedrijf_TCRUD.Data.FinancieelContactpersoon.Telefoon,
                         Bedrijf_TCRUD.Data.StamAantalMedewerkers.Omschrijving,
                         Bedrijf_TCRUD.Data.RelatieStam.Naam]);
  Bedrijf_TCRUD.Data.HoofdContactPersoon.Mobiel.TypedString;
  Bedrijf_TCRUD.Data.StamBranche.Omschrijving.TypedString;
  Bedrijf_TCRUD.Data.StamRechtsvorm.Omschrijving.TypedString;
  Bedrijf_TCRUD.Data.FinancieelContactpersoon.Telefoon.TypedString;
  Bedrijf_TCRUD.Data.StamAantalMedewerkers.Omschrijving.TypedString;
  Bedrijf_TCRUD.Data.RelatieStam.Naam.TypedString;
  Bedrijf_TCRUD.NewQuery;

  Relatie_TCRUD.Data.RelatieStam.ID;          //na relatiestam niet meer doorjoinen naar Relatie_T (circulair)
  Relatie_TCRUD.Data.Relatie.Relatie.Relatie.Relatie.RelatieStam.ID;  //binnen relatie_t wel oneindig doorjoinen, totdat een circulaire join gebruikt wordt

  //Relatie_T is als enige zonder "seperate model" aangemaakt, dus deze is wel doorjoinable (maar na RelatieStam stopt het weer)
  RelatieStamCRUD.Data.FactuurRelatie.Relatie.RelatieStam.ID;
  //RelatieStamCRUD.Data.FactuurRelatie.ID;     //idem: vanuit relatiestam crud wel naar relatie_T, maar dan stopt het doorjoinen
  }
end;

procedure TCRUDTester.TestFindQuery;
var
  connection: TBaseConnection;
begin
  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID]);

  Check(TESTCRUD.QueryFindFirst, 'Should have records in TEST table');
  Check(TESTCRUD.QueryFindCount > 1, 'Should have more than 1 record in TEST table');

  try
    repeat
      //TESTCRUD in "find dataset" mode, guard against changing crud while in repeat loop
      TESTCRUD.QuerySearchSingle;
      Check(False, 'Should raise exception because of pending Find dataset!');
    until not TESTCRUD.QueryFindNext;
  except
    Check(True);  //should raise exception
  end;

  try
    repeat
      //TESTCRUD in "find dataset" mode, guard against changing crud while in repeat loop
      TESTCRUD.QueryFindFirst;
      Check(False, 'Should raise exception because of pending Find dataset!');
    until not TESTCRUD.QueryFindNext;
  except
    Check(True);  //should raise exception
  end;

  repeat
  until not TESTCRUD.QueryFindNext;
  TESTCRUD.QuerySearchSingle;         //loop is finished now, so safe to do an other query
  Check(True); //ok

  //test offline
  TESTCRUD.QueryFindFirst;
  connection := TDBConnectionPool.GetConnectionFromPool(TESTCRUD.GetProvider.GetDBSettings);
  try
    connection.Close;
    repeat
      Check(TESTCRUD.QueryFindCount > 1, 'Should have more than 1 record in TEST table');
    until not TESTCRUD.QueryFindNext;
  finally
    TDBConnectionPool.PutConnectionToPool(TESTCRUD.GetProvider.GetDBSettings, connection);
  end;
  Check(True); //ok
end;

procedure TCRUDTester.TestJoinAliases;
var
  localCRUD: TTESTCRUD;
begin
  localCRUD := TTESTCRUD.Create;
  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID,
                    localCRUD.Data.ID])
    .InnerJoin.OnFields(localCRUD.Data.ID,
                        TESTCRUD.Data.ID)
      .AndJoin.OnFieldAndValue(localCRUD.Data.ID, 1);
  TESTCRUD.QuerySearchSingle;
end;

procedure TCRUDTester.TestRetrieveRecord;
var
  id: integer;
  LocalCrud: TTESTCRUD;
begin
   LocalCrud := TTESTCRUD.Create;
   LocalCrud.NewQuery
    .Select.Fields([LocalCrud.Data.ID]);
  Check( LocalCrud.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  id := LocalCrud.Data.ID.TypedID.ID;
  if id <= 0 then
    Assert(False);

  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID]);
  Check( TESTCRUD.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  id := TESTCRUD.Data.ID.TypedID.ID;

  TESTCRUD.ClearAll;
  TESTCRUD.RecordRetrieve(id, [TESTCRUD.Data.ID]);
  CheckEquals(id, TESTCRUD.Data.ID.TypedID.ID, 'this id should be loaded');
  Check(TESTCRUD.Data.Datum.IsEmpty, 'field is not fetched');

  CheckFalse(TESTCRUD.Data.IsModified);
end;

procedure TCRUDTester.TestSQLQueries;
begin
  TESTCRUD.NewQuery
    .Select.AllFieldsOf(TESTCRUD.Data)
    .Where
      .OpenBracket
            .FieldValue(TESTCRUD.Data.ID).Equal('1')
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).NotEqual('1')
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).ISValue(null)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).ISNotValue(null)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).GreaterThan(1)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).GreaterOrEqual(1)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).LessThan(1)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).LessOrEqual(1)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).Like('%' + '1' + '%')
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).InSet([1])
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).NotInSet([1])
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).EqualField(TESTCRUD.Data.ID)
         .AndWhere
            .FieldValue(TESTCRUD.Data.ID).NotEqualField(TESTCRUD.Data.ID)
         .AndWhere.FieldValue(TESTCRUD.Data.ID).isNull()     
         .AndWhere.FieldValue(TESTCRUD.Data.ID).isNotNull()
      .CloseBracket;
  TESTCRUD.QuerySearchSingle;
end;

type
  TCustomGrid_Hack = class(TDBGrid);

procedure TCRUDTester.TestTableHints;
var
  localCRUD: TTESTCRUD;
begin
  localCRUD := TTESTCRUD.Create;
  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID,
                    localCRUD.Data.ID])
    .WithTableHints([READPAST, NOWAIT])
    .InnerJoin.OnFields(localCRUD.Data.ID,
                        TESTCRUD.Data.ID)
    .WithJoinTableHints([READPAST, NOWAIT])
    .AndJoin.OnFieldAndValue(localCRUD.Data.ID, 1);
  TESTCRUD.QuerySearchSingle;

//  TESTCRUD.NewQuery
//   .Update.WithTableHints([ROWLOCK])
//      .SetField(TESTCRUD.Data.Datum)
//      .WithValue(now)
//      .Where.FieldValue(TESTCRUD.Data.ID)
//            .Equal(69);
//   TESTCRUD.QueryExecute(True);

  localCRUD.Free;
end;

procedure TCRUDTester.TestTDataset;
var
  ds: TCustomCRUDDataset<TTESTCRUD>;
  dsrc: tdatasource;
  dbgrd: TDBGrid;
  f: TForm;
  i: Integer;
  stekst: string;
begin
  TESTCRUD.NewQuery
    .Select.AllFieldsOf(TESTCRUD.Data);
  if TESTCRUD.QuerySearchCount <= 0 then
  begin
    TESTCRUD.Data.ID.TypedID := TBaseIDValue.Get<TTEST_ID>(1);
    TESTCRUD.Data.Datum.TypedDateTime := now;
    TESTCRUD.Data.Tekst.TypedString   := 'test';
    TESTCRUD.RecordCreate;
  end;

  ds := TCustomCRUDDataset<TTESTCRUD>.Create(TESTCRUD);
  try
    ds.Open;
    Check(ds.RecordCount > 0, 'if no record, then we can''t check anything');

    //forward
    for i := 0 to ds.RecordCount - 1 do
    begin
      CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, ds.FieldByName('Tekst').AsString);
      ds.Next;
    end;
    Check(ds.Eof);

    ds.First;
    CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, ds.FieldByName('Tekst').AsString);
    ds.Last;
    CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, ds.FieldByName('Tekst').AsString);

    //backwards
    for i := 0 to ds.RecordCount - 1 do
    begin
      CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, ds.FieldByName('Tekst').AsString);
      ds.Prior;
    end;
    Check(ds.Bof);

    //test editing
    stekst := FormatDateTime('hhnnsszzz', Now);
    ds.Edit;
    ds.FieldByName(TESTCRUD.Data.Tekst.FieldName).AsString := stekst;
    CheckEqualsString(stekst, ds.FieldByName(TESTCRUD.Data.Tekst.FieldName).AsString);
    //Check(TESTCRUD.Data.Tekst.TypedString <> ds.FieldByName('Tekst').AsString, 'changes not saved yet');  direct write to crud
    //Check(TESTCRUD.Data.Tekst.TypedString <> stekst);
    ds.Post;  //post: save in crud
    CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, stekst);
    CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, ds.FieldByName('Tekst').AsString);
    Check(TESTCRUD.Data.Tekst.IsModified);
    TESTCRUD.RecordUpdate;
    //check saved in db
    ds.Close;
    i := TESTCRUD.Data.ID.TypedIDValue;
    TESTCRUD.RecordRetrieve(i);
    CheckEqualsString(TESTCRUD.Data.Tekst.TypedString, stekst);

    //to test grid, we need a visible/showing form etc, otherwise counts etc don't work?
    f     := tform.Create(nil);
    dsrc  := TDataSource.Create(f);
    dbgrd := TDBGrid.Create(f);
    try
      f.Show;
      Application.ProcessMessages;

      //reopen, otherwise it does not work too?
      ds.Close;
      TESTCRUD.NewQuery
        .Select.AllFieldsOf(TESTCRUD.Data);
      ds.Open;

      dbgrd.Parent := f;
      dsrc.DataSet := ds;
      dbgrd.DataSource := dsrc;
      ds.Last;
      ds.First;

      //show all rows, otherwise we cannot check on valid .RowCount! @#$%!&@#$@$!
      dbgrd.Height := (TCustomGrid_Hack(dbgrd).DefaultRowHeight + 2) *
                      TESTCRUD.QueryFindCount +
                      50;
      f.Height := dbgrd.Height + 20;   //anders klopt de count niet...
      //does not work:
//      TCustomGrid_Hack(dbgrd).TopRow := TESTCRUD.QueryFindCount;
//      TCustomGrid_Hack(dbgrd).LayoutChanged;
//      TCustomGrid_Hack(dbgrd).Row := TESTCRUD.QueryFindCount;
//      TCustomGrid_Hack(dbgrd).Scroll(TESTCRUD.QueryFindCount);
      Application.ProcessMessages;

      ds.Last;
      CheckEquals( TESTCRUD.QueryFindCount, TCustomGrid_Hack(dbgrd).RowCount - TCustomGrid_Hack(dbgrd).FixedRows);
      //CheckEqualsString(TESTCRUD.Data.Tekst.TypedString,
      //                  TCustomGrid_Hack(dbgrd).GetFieldValue(ds.FieldByName('Tekst').Index) );
    finally
      f.Free;
    end;

  finally
    ds.Free;
  end;
end;

type
  TTEST2 = class(TDataRecord)
  public
    [Meta.TEST.TEST(ID)]    property  ID2       : TTypedTEST_IDField         index   0 read GetTypedTEST_IDField;
    [Meta.TEST.TEST(Datum)] property  Datum2    : TTypedDateTimeField        index   1 read GetDateTimeField;
    [Meta.TEST.TEST(Tekst)] property  Tekst2    : TTypedStringField          index   2 read GetStringField;
  end;
  TTESTCRUD2 = class(TDataCRUD<TTEST2>);

procedure TCRUDTester.TestTDatasetPropertyDisplaylabel;
var
  test2: TTESTCRUD2;
  ds: TCustomCRUDDataset<TTESTCRUD2>;
begin
  test2 := TTESTCRUD2.Create;
  try
    test2.Data.Tekst2.DisplayLabel := 'my' + test2.Data.Tekst2.DisplayLabel;

    ds := TCustomCRUDDataset<TTESTCRUD2>.Create(test2);
    try
      ds.Open;
      CheckEqualsString(test2.Data.Tekst2.DisplayLabel, ds.FieldByName(test2.Data.Tekst2.PropertyName).DisplayName );
    finally
      DS.Free;
    end;
  finally
    test2.Free;
  end;
end;

procedure TCRUDTester.TestTDatasetUniquename;
var
  temp: TTempCRUD;
  t1, t2: TTESTCRUD;
  ds: TCustomCRUDDataset<TTempCRUD>;
begin
  temp := TTempCRUD.Create;
  t1   := TTESTCRUD.Create;
  t2   := TTESTCRUD.Create;
  try
    t1.Data.Tekst.DisplayLabel := 'test1';
    t2.Data.Tekst.DisplayLabel := 'test2';

    temp.Data.Add(t1.Data.ID);
    temp.Data.Add(t1.Data.Tekst);
    temp.Data.Add(t2.Data.Tekst);

    temp.NewQuery
      //.Select.Fields([t1.Data.Tekst, t2.Data.Tekst])
      .Select.AllFieldsOf(temp.Data)
      .InnerJoin.OnFields(t2.Data.ID, t1.Data.ID);
    temp.QueryFindFirst;

    ds := TCustomCRUDDataset<TTempCRUD>.Create(temp);
    try
      ds.Open;

//      ds.FieldByName()
//      ds.FieldByCRUDField()
//      compare displaylabel, must be different fields
    finally
      ds.Free;
    end;

  finally
    temp.Free;
    t1.Free;
    t2.Free;
  end;
end;

procedure TCRUDTester.TestThreadFinalization;
var obj: TObject;
begin
  obj := TTESTCRUD.Create;  //adds to TThreadFinalization
  obj.Free;                 //must remove itself from TThreadFinalization again (without AV)
  Check( not TThreadFinalization.ContainsThreadObject(obj) ); //must not exist
end;

procedure TCRUDTester.TestUpdateRecord;
const
   TestTekst1 = 'test12345';
var
  id: integer;
  stekst: string;
begin
  TESTCRUD.NewQuery
    .Select.AllFieldsOf(TESTCRUD.Data);
  Check( TESTCRUD.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  id := TESTCRUD.Data.ID.TypedIDValue;

  stekst := FormatDateTime('hhnnsszzz', Now);
  TESTCRUD.Data.Tekst.TypedString := stekst;
  TESTCRUD.RecordUpdate;

  TESTCRUD.NewQuery
    .Select.AllFieldsOf(TESTCRUD.Data)
    .Where.FieldValue(TESTCRUD.Data.ID)
          .Equal     (id);
  Check( TESTCRUD.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  CheckEqualsString(stekst, TESTCRUD.Data.Tekst.TypedString, 'tekst moet gewijzigd zijn in de DB');

  TESTCRUD.NewQuery.Update
         .SetField(TESTCRUD.Data.Tekst).WithValue(TestTekst1)
         .Where.FieldValue(TESTCRUD.Data.ID).Equal(id);
  TESTCRUD.QueryExecute();

  TESTCRUD.NewQuery
    .Select.AllFieldsOf(TESTCRUD.Data)
     .Where.FieldValue(TESTCRUD.Data.ID).Equal(id);
  Check( TESTCRUD.QuerySearchSingle, 'DB moet test record bevatten ivm "TestCreateRecord"');
  CheckEquals(TESTCRUD.Data.Tekst.TypedString, TestTekst1);

  try
   TESTCRUD.NewQuery.Update
      .SetField(TESTCRUD.Data.Tekst).WithValue(TestTekst1)
      .Where.FieldValue(TESTCRUD.Data.ID).Equal(-1);
   TESTCRUD.QueryExecute();
  except

  end;
end;

procedure TCRUDTester.TestWhereParameter;
var
  wp: IWhere_Standalone;
begin
  wp := TWhereBuilder.Create;
  wp.FieldValue(TESTCRUD.Data.ID).Equal(1);

  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID])
    .Where.FieldValue(TESTCRUD.Data.Datum).Equal(Date);
  TESTCRUD.Query.CurrentSelect.AndWhere(wp);
  TESTCRUD.QuerySearchSingle;

  wp := TWhereBuilder.Create;
  wp.FieldValue(TESTCRUD.Data.ID).Equal(1);

  TESTCRUD.NewQuery
    .Select.Fields([TESTCRUD.Data.ID]);
  TESTCRUD.Query.CurrentSelect.AndWhere(wp);
  TESTCRUD.QuerySearchSingle;
end;

end.
