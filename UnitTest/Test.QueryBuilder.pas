unit Test.QueryBuilder;

interface

uses
  Classes,
  TestFramework,
  System.SysUtils;

type
  TQueryTester = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSelectRecord;
    procedure TestSearchCount;
    procedure TestGrouping;
  end;

implementation

uses
   CRUD.TEST, DB.Connection, DB.ConnectionPool;

{ TQueryTester }

procedure TQueryTester.SetUp;
begin
   inherited;

end;

procedure TQueryTester.TearDown;
begin
  inherited;

end;

procedure TQueryTester.TestGrouping;
begin
   TESTCRUD.ClearAll;
   TESTCRUD.NewQuery
      .Select.Min(TESTCRUD.Data.Datum)
      .GroupBy([TESTCRUD.Data.Datum] );
   TESTCRUD.QuerySearchSingle;
end;

procedure TQueryTester.TestSearchCount;
var Count: Integer;
begin
   TESTCRUD.ClearAll;
   TESTCRUD.NewQuery
      .Select.AllFieldsOf(TESTCRUD.Data)
      .Where.FieldValue(TESTCRUD.Data.ID)
      .Equal(-1);
//   TESTCRUD.QueryExecute();
   Count :=  TESTCRUD.QuerySearchCount;
   CheckEquals(True, (Count = 0));

   TESTCRUD.ClearAll;
   TESTCRUD.NewQuery
      .Select.AllFieldsOf(TESTCRUD.Data);
//   TESTCRUD.QueryExecute();
   Count :=  TESTCRUD.QuerySearchCount;
   CheckEquals(True, (Count > 0));
end;

procedure TQueryTester.TestSelectRecord;
var ID: Integer;
    DefaultTekst: string;

   procedure GenerateTestCase();
   begin
      DefaultTekst := TESTCRUD.Data.Tekst.DefaultValue;
      TESTCRUD.Data.Clear2EmptyOrDefault;
      TESTCRUD.Data.Datum.TypedDateTime := Now;
      TESTCRUD.RecordCreate;
      ID := TESTCRUD.Data.ID.TypedIDValue;
   end;

begin
   //
   GenerateTestCase;

   TESTCRUD.ClearAll;
   CheckEquals(True, TESTCRUD.Data.ID.IsEmpty);

   TESTCRUD.NewQuery
      .Select.AllFieldsOf(TESTCRUD.Data)
      .Where.FieldValue(TESTCRUD.Data.ID).Equal(ID);
   TESTCRUD.QuerySearchSingle;
   //Query moet het net aangemaakte record opleveren
   CheckEquals(ID, TESTCRUD.Data.ID.TypedIDValue);
   CheckEquals(DefaultTekst, TESTCRUD.Data.Tekst.TypedString);

   //De tekst met een waarde vullen
   TESTCRUD.Data.Tekst.TypedString := 'Niet null';
   TESTCRUD.RecordUpdate;

   TESTCRUD.ClearAll;
   CheckEquals(True, TESTCRUD.Data.ID.IsEmpty);

   //Query moet nu geen resultaat meer opleveren
   TESTCRUD.NewQuery
      .Select.AllFieldsOf(TESTCRUD.Data)
      .Where.FieldValue(TESTCRUD.Data.ID).Equal(ID)
      .AndWhere.FieldValue(TESTCRUD.Data.Tekst).IsNull;
   CheckEquals(False, TESTCRUD.QuerySearchSingle);

   TESTCRUD.ClearAll;
   CheckEquals(True, TESTCRUD.Data.ID.IsEmpty);

   TESTCRUD.NewQuery
      .Select.AllFieldsOf(TESTCRUD.Data)
      .Where.FieldValue(TESTCRUD.Data.ID).Equal(ID)
      .AndWhere.FieldValue(TESTCRUD.Data.Tekst).IsNotNull;
   TESTCRUD.QuerySearchSingle;

   //Query moet één record opleveren
   TESTCRUD.QuerySearchSingle;
   CheckEquals(ID, TESTCRUD.Data.ID.TypedIDValue);
   CheckEquals(False, TESTCRUD.Data.Tekst.IsNull);
end;

end.
