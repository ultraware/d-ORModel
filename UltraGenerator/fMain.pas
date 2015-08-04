unit fMain;

interface

uses
  Generics.Collections, ComCtrls, Vcl.Grids, Windows, SysUtils, Classes,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls,
  Meta.Data, Data.CRUDSettings;

type
  TTableDependencies = class(TObjectDictionary<TCRUDTable, TList<TCRUDTable>>);

  TfrmMain = class(TForm)
    Panel1: TPanel;
    btnLoadTables: TButton;
    btnGenerate: TButton;
    pbGenerate: TProgressBar;
    spl1: TSplitter;
    pnl1: TPanel;
    grdTables: TStringGrid;
    pnl2: TPanel;
    grdFields: TStringGrid;
    lbl1: TLabel;
    lblFields: TLabel;
    cmbxCustomType: TComboBox;
    btnSaveXML: TButton;
    Panel2: TPanel;
    btnGenerateTable: TButton;
    Button1: TButton;
    btnDeps: TButton;
    cbbTypeCmbx: TComboBox;
    cbbSkipDefault: TComboBox;
    cbbVisible: TComboBox;
    btnDBSettings: TButton;
    procedure btnLoadTablesClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure pnl1Resize(Sender: TObject);
    procedure grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure grdFieldsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure grdFieldsSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure cmbxCustomTypeSelect(Sender: TObject);
    procedure btnSaveXMLClick(Sender: TObject);
    procedure btnGenerateTableClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnDepsClick(Sender: TObject);
    procedure cbbTypeCmbxSelect(Sender: TObject);
    procedure grdFieldsGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure cbbSkipDefaultSelect(Sender: TObject);
    procedure cbbVisibleSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnDBSettingsClick(Sender: TObject);
  private
    function CurrentTable: TCRUDTable;
    function CurrentField: TCRUDField;
    procedure FillFieldsForTable(const aTable: TCRUDTable);

    function  GetTablesWithCircularDeps: TTableDependencies;
    procedure InitCircularDepsFix;

    procedure LoadFields(aTbl: TCRUDTable);
    procedure DoGenerateTable(const t: TCRUDTable; const Silent: Boolean = False);
  public
    procedure  AfterConstruction; override;

    function AddTable(const aTablename: string; const aIsDataBaseTable: Boolean = True; const aParameterCount: Integer = 0): TCRUDTable;
  end;

  TAutomaticCustomTypeList = class(TDictionary<string,string>);

var
  frmMain: TfrmMain;
  FieldNameCustomTypesDict: TAutomaticCustomTypeList;
  FKTablenameCustomTypesDict: TAutomaticCustomTypeList;
  FieldNameDisplayNameDict: TAutomaticCustomTypeList;

implementation

uses
  TypInfo, ADODB, StrUtils, System.MaskUtils, UITypes,
  DB.ConnectionPool, Data.DataRecord, DB.Connection.SQLServer, DB.Settings,
  UltraStringUtils, fModelGenerator, uGenerator, uMetaLoader,
  fDBSettings, DB.Settings.SQLServer;

type TGridField = (cFld_Fieldname, cFld_Type, cFld_CustomType, cFld_Stamsoort, cFld_Required, cFld_MinValue, cFld_MaxValue, cFld_Displaylabel, cFld_DisplayFormat, cFld_DisplayWidth, cFld_EditFormat, cFld_EditMask, cFld_FKTable, cFld_FK_Field, cFld_SkipDefault, cFld_SVisible);
const C_GridFieldIndex: array[TGridField] of Integer = (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15);
      C_GridFieldName:  array[TGridField] of string = ('FieldName','Type','CustomType','Stamsoort','Required','MinValue','MaxValue','Displaylabel','DisplayFormat','Displaywidth','EditFormat','EditMask','ForeignKeyTable','ForeignKeyField','SkipDefault', 'Visible');

{$R *.dfm}

procedure TfrmMain.AfterConstruction;
var
  tbl: TCRUDTable;
  i: Integer;
  FType: Meta.Data.TFieldType;
begin
  inherited;

  btnLoadTables.Click;
  grdTables.Row := 1;
  LoadFields(CurrentTable);

  cmbxCustomType.Items.Clear;
  cmbxCustomType.Items.Add('');
  for i := 0 to TRegisteredCustomFields.Count-1 do
    cmbxCustomType.Items.Add( TRegisteredCustomFields.Item[i].ClassName );

   // Alle IDs toevoegen aan customtypes zodat views deze ook kunnen gebruiken, daar worden geen foreign keys gevonden
   cmbxCustomType.Items.Add('');
   for tbl in CRUDSettings.Tables do
   begin
      if tbl.IsDataBaseTable then
         cmbxCustomType.Items.Add(Format('TTyped%s_IDField', [tbl.TableName]));
   end;

  cbbTypeCmbx.Items.Clear;
   for FType := low(Meta.Data.TFieldType) to high(Meta.Data.TFieldType) do
    cbbTypeCmbx.Items.Add(TypInfo.GetEnumName(TypeInfo(Meta.Data.TFieldType), Ord(FType) ));
//    cbbTypeCmbx.Items.Add(C_FieldTypeName[FType]);

  cbbSkipDefault.Items.Clear;
  cbbSkipDefault.Items.Add('True');
  cbbSkipDefault.Items.Add('False');

   cbbVisible.Items.Clear;
   cbbVisible.Items.Add('True');
   cbbVisible.Items.Add('False');

//  cmbxCustomType.Height     := grdFields.DefaultRowHeight + 2;
//  cmbxCustomType.ItemHeight := grdFields.DefaultRowHeight;
end;

procedure TfrmMain.btnDBSettingsClick(Sender: TObject);
begin
   if TDBSettingsFrm.CreateAndShowModal then
      btnLoadTablesClick(Sender);
end;

procedure TfrmMain.btnDepsClick(Sender: TObject);
var
  deps: TTableDependencies;
  lst: TList<TCRUDTable>;
  s: string;
  t, t2: TCRUDTable;
begin
  deps := GetTablesWithCircularDeps;
  try
    for t in deps.Keys do
    begin
      lst := deps.Items[t];
      s := '';
      for t2 in lst do
      begin
        if s = '' then
          s := t2.TableName
        else
          s := s + ', ' + t2.TableName;
      end;
      s := 'Circular dependencies of "' + t.TableName + '" are: '#13 + s;
      MessageDlg(s, mtWarning, [mbOK], 0);
    end;
  finally
    deps.Free;
  end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var t: TCRUDTable;
begin
  pbGenerate.Position := 0;
  pbGenerate.Visible  := True;
  btnGenerate.Enabled := False;
  try
    Self.Update;

    pbGenerate.Max  := CRUDSettings.TableCount;
    pbGenerate.Step := 1;

    for t in CRUDSettings.Tables do
    begin
      pbGenerate.StepIt;
      if pbGenerate.Position mod 10 = 0 then
        Self.Update;

      //refresh fields of table
      try
         LoadFields(t);
      except
         continue;
      end;

      DoGenerateTable(t, True { Silent } );
    end;
    // Custom ID types updaten
    TGenerator.GenerateCustomMetaTypesOfAllTables;
  finally

    pbGenerate.Visible := False;
    btnGenerate.Enabled := True;
  end;
end;

procedure TfrmMain.DoGenerateTable(const t: TCRUDTable; const Silent: Boolean = False);
begin
   TGenerator.GenerateCRUDForTable(t);
   TGenerator.GenerateMetaForTable(t);
   if TGenerator.TablesWithSeperateModels.IndexOf(t.TableName) >= 0 then
     //if t.TableName = 'Relatie_T' then
     TGenerator.GenerateModelForTable(t);
end;

procedure TfrmMain.btnGenerateTableClick(Sender: TObject);
begin
  btnGenerateTable.Enabled := False;
  try
      DoGenerateTable(CurrentTable);
      // Custom IDs updaten
      TGenerator.GenerateCustomMetaTypesOfAllTables;
  finally
    btnGenerateTable.Enabled := True;
  end;
end;

procedure TfrmMain.btnLoadTablesClick(Sender: TObject);
   procedure StartLoading;
   var sTbl: TCRUDTable;
    begin
      for sTbl in CRUDSettings.Tables do
         sTbl.Exists := False;
    end;

   procedure FinishLoading;
   var sTbl: TCRUDTable;
   begin
      for sTbl in CRUDSettings.Tables do
    begin
         if (not sTbl.Exists) then
            CRUDSettings.DeleteTable(sTbl);
    end;
      InitCircularDepsFix; // altijd doen, anders een individueel gemaakte CRUD soms anders dan als ze allemaal gemaakt worden
  end;

var
  connection: TBaseADOConnection;
  mssql: TMSSQLConnection;
  ds: TADODataSet;
  dbconn: TDBConfig;
begin
  grdTables.RowCount  := 1;
  grdTables.RowCount  := 2;
  grdTables.Cells[0, 0] := 'Tablename';
  grdTables.FixedRows := 1;

  dbconn := TDBSettings.Instance.GetDBConnection('', dbtNone);  //get specific settings or first in case no dbtype etc
   Connection := TDBConnectionPool.GetConnectionFromPool(dbconn) as TBaseADOConnection;
  //connection := TDBConnectionPool.GetConnectionFromPool as TBaseADOConnection;
  try
      Assert(Connection is TMSSQLConnection);
      mssql := (Connection as TMSSQLConnection);
    connection.Open;

      Self.Caption := Format('Generator for: Server = %s - DB = %s',[mssql.ServerName,mssql.DataBase]);

      ds := TADODataSet.Create(nil);
    try
      ds.Close;
      //mssql.Connection.DefaultDatabase := 'CompendaTest';
         // if mssql.IsSQLServerCE then
         // begin
        //strange, does not work with SQL CE
        with TADOCommand.Create(nil) do
        try
          ConnectionString := mssql.ADOConnection.ConnectionString;
               if mssql.IsSQLServerCE then
                  CommandText := 'SELECT TABLE_TYPE, TABLE_NAME, 0 as PARAMETERCOUNT '+
                     'FROM INFORMATION_SCHEMA.TABLES'
               else
                  CommandText := 'SELECT TABLE_TYPE, TABLE_NAME, 0 as PARAMETERCOUNT  '+
                     'FROM INFORMATION_SCHEMA.TABLES ' +
                     'UNION ALL '+
                     'SELECT ''FUNCTION'', O.NAME, COUNT(P.OBJECT_ID) '+
                     'FROM SYS.OBJECTS O ' +
                        'INNER JOIN SYS.PARAMETERS p ON (O.OBJECT_ID = P.OBJECT_ID) ' +
                     'WHERE O.TYPE in (''IF'',''TF'') ' +
                     'GROUP BY O.NAME ' +
                     'ORDER BY TABLE_NAME';

               // CommandText := 'SELECT ''FUNCTION'' as TABLE_TYPE, name as TABLE_NAME FROM sys.objects   WHERE type in (''IF'',''TF'')';
          ds.Recordset := Execute;
        finally
          Free;
            end;
         // end
         // else
         // mssql.ADOConnection.OpenSchema(siTables, EmptyParam, EmptyParam, ds);

      ds.First;
         StartLoading;
      while not ds.Eof do
      begin
        // <z:row TABLE_CATALOG='prdIE' TABLE_SCHEMA='dbo' TABLE_NAME='vrdMutatieExport' TABLE_TYPE='TABLE' DATE_CREATED='2008-04-11T15:43:46'/>
            if StringIn(ds.FieldByName('TABLE_TYPE').AsString, 'BASE TABLE,TABLE,VIEW,FUNCTION') then
        begin
               AddTable(ds.FieldByName('TABLE_NAME').AsString, StringIn(ds.FieldByName('TABLE_TYPE').AsString, 'BASE TABLE,TABLE'),
                  ds.FieldByName('PARAMETERCOUNT').AsInteger);
        end;

        ds.Next;
      end;
         if Assigned(TGeneratorSettings.OnCreateTempTableDefs) then
            TGeneratorSettings.OnCreateTempTableDefs();
         FinishLoading;
    finally
      ds.Free;
    end;
  finally
      TDBConnectionPool.PutConnectionToPool(dbconn, Connection);
  end;

  grdTables.RowCount := grdTables.RowCount - 1;
end;

function TfrmMain.AddTable(const aTablename: string; const aIsDataBaseTable: Boolean = True; const aParameterCount: Integer = 0): TCRUDTable;
begin
   //tbl := TCRUDTable.Create;
   Result := CRUDSettings.FindTable(aTablename, True{auto create});
   //tbl.Database   := mssql.ADOConnection.DefaultDatabase;
   Result.TableFunctionParameterCount := aParameterCount;
   Result.IsDataBaseTable := aIsDataBaseTable;
   Result.CanLoadFromDB := True;
   Result.Exists := True;

   grdTables.Cells  [0, grdTables.RowCount-1] := aTablename;
   grdTables.Objects[0, grdTables.RowCount-1] := Result;
   grdTables.RowCount := grdTables.RowCount + 1;
end;

procedure TfrmMain.btnSaveXMLClick(Sender: TObject);
begin
  CRUDSettings.SaveToSettingsFile;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  TfrmModelGenerator.CreateAndShowModal;
end;

procedure TfrmMain.cbbSkipDefaultSelect(Sender: TObject);
begin
   CurrentField.SkipDefault := StrToBoolDef(cbbSkipDefault.Text, False);
  grdFields.Cells[grdFields.Col, grdFields.Row] := cbbSkipDefault.Text;
end;

procedure TfrmMain.cbbTypeCmbxSelect(Sender: TObject);
begin
   CurrentField.FieldType := cbbTypeCmbx.Text;
  grdFields.Cells[grdFields.Col, grdFields.Row] := cbbTypeCmbx.Text;
end;

procedure TfrmMain.cbbVisibleSelect(Sender: TObject);
begin
   CurrentField.Visible := StrToBoolDef(cbbVisible.Text, False);
   grdFields.Cells[grdFields.Col, grdFields.Row] := cbbVisible.Text;
end;

procedure TfrmMain.cmbxCustomTypeSelect(Sender: TObject);
begin
   CurrentField.CustomType := cmbxCustomType.Text;
  grdFields.Cells[grdFields.Col, grdFields.Row] := cmbxCustomType.Text;
end;

function TfrmMain.CurrentTable: TCRUDTable;
begin
   Result := grdTables.Objects[0, grdTables.Row] as TCRUDTable
end;

function TfrmMain.CurrentField: TCRUDField;
begin
   Result := grdFields.Objects[0, grdFields.Row] as TCRUDField;
end;

procedure TfrmMain.FillFieldsForTable(const aTable: TCRUDTable);
begin
  TMetaLoader.FillFieldsForTable(aTable);
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  case MessageDlg('Wijzigingen in xml opslaan?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
    begin
      CanClose := True;
      btnSaveXML.Click;
    end;
      mrNo:
         CanClose := True;
      mrCancel:
         Abort;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
   inherited;
   
   with CRUDSettings.DB do
   begin
      if ((Server <> '') and (DB <> '')) then
         //EndsText('.sdf', Server) then       also needs to store CE type!
      begin
         try
            AddSQLDatabaseSettings(Server, DB, DBUser, DBPwd)
         Except
            // als connectie niet gevonden kan worden met instellingen, dan instellingen maar wijzigen
            btnDBSettingsClick(Sender);
         end;
      end
      else
         btnDBSettingsClick(Sender);
   end;
end;

procedure TfrmMain.grdFieldsGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
   case TGridField(ACol) of
      cFld_MinValue,
      cFld_MaxValue: Value := FloatToStr(StrToFloatDef(Value,0));
      cFld_DisplayWidth: Value := IntToStr(StrToIntDef(Value,0));
   end;
end;

procedure TfrmMain.grdFieldsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);

  procedure SelectWithCombo(cmb: TComboBox; InitValue: string);
  var r: TRect;
  begin
    CanSelect := True;
    r         := grdFields.CellRect(ACol, ARow);
    cmb.Top     := grdFields.Top + r.Top + 1;
    cmb.Left    := r.Left + 1;
    cmb.Height  := r.Height;
    cmb.Visible := True;
    cmb.ItemIndex := cmb.Items.IndexOf(InitValue);
    cmb.Width   := r.Width;
  end;

var f: TCRUDField;
begin
  CanSelect := False;
  cmbxCustomType.Visible := False;
  cbbTypeCmbx.Visible := False;
  cbbSkipDefault.Visible := False;
   cbbVisible.Visible := False;
   f := CurrentField;

  case TGridField(ACol) of
//     cFld_Fieldname: ;
     cFld_Type:
        SelectWithCombo(cbbTypeCmbx, f.FieldType);
     cFld_CustomType:
         begin
            if (not(f.IsPK or f.IsFK)) then
        SelectWithCombo(cmbxCustomType, f.CustomType);
         end;
//     cFld_Requiered: ;
      cFld_MinValue, cFld_MaxValue, cFld_Displaylabel, cFld_DisplayFormat, cFld_DisplayWidth, cFld_EditFormat, cFld_EditMask:
         CanSelect := True;
     cFld_SkipDefault:
     begin
       if f.HasDefault then
          SelectWithCombo(cbbSkipDefault, IfThen(f.SkipDefault, 'True', 'False'));
     end;
      cFld_SVisible:
         SelectWithCombo(cbbVisible, IfThen(f.Visible, 'True', 'False'));
  end;

  if not CanSelect then
  begin
    grdFields.OnSelectCell := nil;
    grdFields.Row          := ARow;
    grdFields.Col          := C_GridFieldIndex[cFld_Displaylabel];
//    grdFields.Col          := 0;
    grdFields.OnSelectCell := grdFieldsSelectCell;
  end;
end;

procedure TfrmMain.grdFieldsSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
var
  f: TCRUDField;
  s: string;
begin
   f := CurrentField;

  case TGridField(ACol) of
//     cFld_Fieldname: ;
     cFld_Type:
         f.FieldType := Value;
     cFld_CustomType:
         f.CustomType := Value;
     cFld_Required:
         f.Required := StrToBool(Value);
     cFld_MinValue:
       f.MinValue := StrToFloatDef(Value, 0);
     cFld_MaxValue:
       f.MaxValue := StrToFloatDef(Value, 0);
     cFld_Displaylabel:
         f.Displaylabel := Value;
     cFld_DisplayFormat:
     begin
       try
         s := FormatFloat(Value, 0);
         s := FormatFloat(Value, 1);
         s := FormatFloat(Value, -1);
       except
         MessageDlg(Format('Invalid format "%s"',[Value]), mtError, [mbOK], 0);
       end;
       f.DisplayFormat := Value
     end;
     cFld_DisplayWidth:
       f.DisplayWidth := StrToIntDef(Value,0);
     cFld_EditFormat:
     begin
       try
         s := FormatFloat(Value, 0);
         s := FormatFloat(Value, 1);
         s := FormatFloat(Value, -1);
       except
         MessageDlg(Format('Invalid format "%s"',[Value]), mtError, [mbOK], 0);
       end;
       f.EditFormat := Value;
     end;
     cFld_EditMask:
     begin
       try
         s := FormatMaskText(Value, '');
       except
         MessageDlg(Format('Invalid mask "%s"',[Value]), mtError, [mbOK], 0);
       end;
       f.EditMask := Value;
     end;
  end;
end;

procedure TfrmMain.grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
   LoadFields(grdTables.Objects[0, ARow] as TCRUDTable); // niet current-table, die wordt nu juist anders :)
end;

procedure TfrmMain.InitCircularDepsFix;
var
  deps: TTableDependencies;
  t: TCRUDTable;
begin
  deps := GetTablesWithCircularDeps;
  try
    for t in deps.Keys do
    begin
         if (TGenerator.TablesWithSeperateModels.IndexOf(t.TableName) < 0) then
        TGenerator.TablesWithSeperateModels.Add(t.TableName);
    end;
  finally
    deps.Free;
  end;
end;

procedure TfrmMain.LoadFields(aTbl: TCRUDTable);
var
  f: TCRUDField;
  row: TStrings;
  GridField: TGridField;
begin
  lblFields.Caption := 'Fields of: none';
  grdFields.RowCount  := 1;
   if aTbl = nil then
      Exit;
  lblFields.Caption := 'Fields of: ' + aTbl.TableName;
  
  grdFields.RowCount  := 1;
  grdFields.FixedCols := 0;
  grdFields.ColCount  := Length(C_GridFieldIndex);
//  grdFields.OnSelectCell := nil;

  //if aTbl.FieldCount = 0 then
  FillFieldsForTable(aTbl);  //refresh
  grdFields.RowCount := aTbl.FieldCount + 1; //grdFields.FixedRows;
  grdFields.Row      := 0; //grdFields.FixedRows;

  for f in aTbl.Fields do
  begin
    grdFields.Row := grdFields.Row + 1;

      Row := grdFields.Rows[grdFields.Row];
      Row.Clear;
    //row.Add('');
      Row.AddObject(f.FieldName, f);
    //row.Add( TypInfo.GetEnumName(TypeInfo(TFieldType), ORd(f.FieldType) ) );
      Row.Add(f.FieldType);
      if (f.CustomType = '') and FieldNameCustomTypesDict.ContainsKey(f.FieldName) then // MutatieDatum -> TTypedMutatieDateTimeField
         f.CustomType := FieldNameCustomTypesDict.Items[f.FieldName];
      if (f.CustomType = '') and f.IsFK and FKTablenameCustomTypesDict.ContainsKey(f.FKTable) then // xxStam_T_ID -> TTypedStam_IDField
         f.CustomType := FKTablenameCustomTypesDict.Items[f.FKTable];
      if SameText(f.FieldName,'WebDB') then
         f.Visible := False;

      Row.Add(f.CustomType);
      Row.Add(BoolToStr(f.Required, True));
//    row.Add(f.DefaultValue);
    //if f.StringSize > 0 then
    //  row.Add(IntToStr(f.StringSize))
    //else
    //  row.Add('');
    if f.MaxValue > 0 then       //maxvalue filled? then show minvalue too
         Row.Add(FloatToStr(f.MinValue))
    else
         Row.Add('');
    if f.MaxValue > 0 then
         Row.Add(FloatToStr(f.MaxValue))
    else
         Row.Add('');

    if FieldNameDisplayNameDict.ContainsKey(f.FieldName) then
       f.Displaylabel := FieldNameDisplayNameDict.Items[f.FieldName];
    if TGeneratorSettings.Vertaalbaar and (Trim(f.Displaylabel) = '') then
    f.Displaylabel := f.FieldName; // voor vertalingen -> moet een displaywaarde ingevuld zijn
    Row.Add(f.Displaylabel);
    Row.Add(f.DisplayFormat);
    if f.DisplayWidth > 0 then
         Row.Add(IntToStr(f.DisplayWidth))
    else
         Row.Add('');
    Row.Add(f.EditFormat);
    Row.Add(f.EditMask);
    Row.Add(f.FKTable);
    Row.Add(f.FKField);
    if f.HasDefault then // anders dus een lege tekst
       Row.Add(IfThen(f.SkipDefault, 'True', 'False'))
    else
       Row.Add('');
    Row.Add(IfThen(f.Visible, 'True', 'False'));
  end;

  row := grdFields.Rows[0];
  row.Clear;
  for GridField := Low(TGridField) to High(TGridField) do
  begin
    row.add(C_GridFieldName[GridField]);
      grdFields.ColWidths[C_GridFieldIndex[GridField]] := 85;
  end;

  if (grdFields.RowCount > 1) then
  begin
    grdFields.FixedRows := 1;
    grdFields.ColWidths[C_GridFieldIndex[cFld_Fieldname]] := 150;
    grdFields.ColWidths[C_GridFieldIndex[cFld_CustomType]] := 175;
    grdFields.ColWidths[C_GridFieldIndex[cFld_Stamsoort]] := 175;
    grdFields.ColWidths[C_GridFieldIndex[cFld_Required]] := 80;
    grdFields.ColWidths[C_GridFieldIndex[cFld_Displaylabel]] := 175;

    grdFields.OnSelectCell := grdFieldsSelectCell;
    grdFields.Col          := C_GridFieldIndex[cFld_Displaylabel];
   end
   else
      CRUDSettings.DeleteTable(atbl);
//   Tabel verwijderen uit xml!, heeft geen velden dus zal wel niet meer bestan
end;

procedure TfrmMain.pnl1Resize(Sender: TObject);
begin
  grdTables.ColWidths[0] := pnl1.Width - 25;
end;

function TfrmMain.GetTablesWithCircularDeps: TTableDependencies;
var
  t, t2: TCRUDTable;
  f: TCRUDField;
  deps: TTableDependencies;
  lst, lst2: TList<TCRUDTable>;

  procedure _GetAllDeps(aTable: TCRUDTable; var aDeps: TList<TCRUDTable>);
   var lst: TList<TCRUDTable>; t: TCRUDTable;
  begin
    lst := deps.Items[aTable];        //aTable = Relatie_T
    for t in lst do
    begin
      if t = aTable then
        continue; // links to self are ok

      if not aDeps.Contains(t) then   //t = Email
      begin
        aDeps.Add(t);
        _GetAllDeps(t, aDeps);
      end;
    end;
  end;

  procedure _AddDeps(aTable: TCRUDTable);
   var lst, lst2: TList<TCRUDTable>; t2: TCRUDTable;
  begin
    lst2 := TList<TCRUDTable>.Create;
    try
      _GetAllDeps(aTable, lst2);

      lst := deps.Items[aTable];
      for t2 in lst2 do
        if not lst.Contains(t2) then
          lst.Add(t2);
    finally
      lst2.Free;
    end;
  end;

begin
  Result := TTableDependencies.Create([doOwnsValues]);

  deps := TTableDependencies.Create([doOwnsValues]);
  try
    //alle tabellen doorlopen
    for t in CRUDSettings.Tables do
    begin
      if not deps.TryGetValue(t, lst) then
      begin
        lst := TList<TCRUDTable>.Create;
        deps.Add(t, lst);
      end;

      //alle velden doorlopen
      for f in t.Fields do
      begin
        //foreign key?
        if f.FKTable <> '' then
        begin
          t2 := CRUDSettings.FindTable(f.FKTable, False{no add});
               if t2 = t then
                  continue; // links to self are ok
          if t2 <> nil then
            if not lst.Contains(t2) then
              lst.Add(t2);
        end;
      end;
    end;

    //2nd pass: recursief alle deps opzoeken
    for t in deps.Keys do
      _AddDeps(t);

    //3nd pass: circular deps?
    for t in deps.Keys do
    begin
      lst := deps.Items[t];
      if lst.Contains(t) then
      begin
        //lst := deps.ExtractPair(t).Value;
        lst2 := TList<TCRUDTable>.Create;
        for t2 in lst do
          lst2.Add(t2);
        Result.Add(t, lst2);
      end;
    end;

  finally
    deps.Free;
  end;
end;

initialization
   FKTablenameCustomTypesDict := TAutomaticCustomTypeList.Create;
   FieldNameCustomTypesDict   := TAutomaticCustomTypeList.Create;
   FieldNameDisplayNameDict   := TAutomaticCustomTypeList.Create;

finalization
   FieldNameCustomTypesDict.Free;
   FKTablenameCustomTypesDict.Free;
   FieldNameDisplayNameDict.Free;

end.
