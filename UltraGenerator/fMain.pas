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
unit fMain;

interface

uses
  Generics.Collections, IOUtils, UITypes,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls,
  Meta.Data, Data.CRUDSettings,
  ComCtrls, Vcl.Grids;

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
    btnGenerateBO: TButton;
    cbbTypeCmbx: TComboBox;
    cbbSkipDefault: TComboBox;
    procedure btnLoadTablesClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure pnl1Resize(Sender: TObject);
    procedure grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure grdFieldsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure grdFieldsSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure cmbxCustomTypeSelect(Sender: TObject);
    procedure btnSaveXMLClick(Sender: TObject);
    procedure btnGenerateTableClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnDepsClick(Sender: TObject);
    procedure btnGenerateBOClick(Sender: TObject);
    procedure cbbTypeCmbxSelect(Sender: TObject);
    procedure grdFieldsGetEditText(Sender: TObject; ACol, ARow: Integer;
      var Value: string);
    procedure cbbSkipDefaultSelect(Sender: TObject);
  private
    class var FOutputCRUDPath: string;
    class var FOutputBOPath: string;
//    FTables: TObjectDictionary<string, TTableModel>;
    procedure FillFieldsForTable(const aTable: TCRUDTable);
    function  GenerateCRUDForTable(const aTable: TCRUDTable): string;
    function  GenerateMetaForTable(const aTable: TCRUDTable): string;
    function  GenerateCustomMetaTypesOfAllTables: TStrings;

    function  GetTablesWithCircularDeps: TTableDependencies;
    procedure InitCircularDepsFix;

    procedure LoadFields(aTbl: TCRUDTable);
    function GenerateBOForTable(const aTable: TCRUDTable): string;
  public
    procedure  AfterConstruction; override;
    destructor Destroy; override;

    class property OutputCRUDPath: string read FOutputCRUDPath write FOutputCRUDPath;
    class property OutputBOPath: string read FOutputBOPath write FOutputBOPath;
  end;

  TAutomaticCustomTypeList = class(TDictionary<string,string>);

var
  frmMain: TfrmMain;
  AutoCustomTypes: TAutomaticCustomTypeList;

implementation

uses
  TypInfo, Math,
  DB.ConnectionPool, DB.Connection, Data.DataRecord,
  ADODB, DB, StrUtils, Data.CustomTypes, fModelGenerator, uGenerator,
  uMetaLoader, DB.Connection.SQLServer, DB.Settings, System.MaskUtils;

type TGridField = (cFld_Fieldname, cFld_Type, cFld_CustomType, cFld_Required, cFld_MinValue, cFld_MaxValue, cFld_Displaylabel, cFld_DisplayFormat, cFld_DisplayWidth, cFld_EditFormat, cFld_EditMask, cFld_FKTable, cFld_FK_Field, cFld_SkipDefault);
const C_GridFieldIndex: array[TGridField] of Integer = (0,1,2,3,4,5,6,7,8,9,10,11,12,13);
      C_GridFieldName:  array[TGridField] of string = ('FieldName','Type','CustomType','Required','MinValue','MaxValue','Displaylabel','DisplayFormat','Displaywidth','EditFormat','EditMask','ForeignKeyTable','ForeignKeyField','SkipDefault');

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
  tbl := grdTables.Objects[0, grdTables.Row] as TCRUDTable;
  LoadFields(tbl);

  cmbxCustomType.Items.Clear;
  cmbxCustomType.Items.Add('');
  for i := 0 to TRegisteredCustomFields.Count-1 do
    cmbxCustomType.Items.Add( TRegisteredCustomFields.Item[i].ClassName );

  cbbTypeCmbx.Items.Clear;
  for FType := Low(Meta.Data.TFieldType) to High(Meta.Data.TFieldType) do
    cbbTypeCmbx.Items.Add(TypInfo.GetEnumName(TypeInfo(Meta.Data.TFieldType), Ord(FType) ));

  cbbSkipDefault.Items.Clear;
  cbbSkipDefault.Items.Add('True');
  cbbSkipDefault.Items.Add('False');
end;

destructor TfrmMain.Destroy;
begin
  inherited;
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

procedure TfrmMain.btnGenerateBOClick(Sender: TObject);
var
  t: TCRUDTable;
  sdir, sfile,
  sdata: string;
begin
   t := grdTables.Objects[0, grdTables.Row] as TCRUDTable;

   btnGenerateBO.Enabled := False;
   try
      if TfrmMain.OutputBOPath = '' then
         TfrmMain.OutputBOPath := ExtractFilePath(Application.ExeName) + 'CRUDs\';
      sdir := TfrmMain.OutputBOPath;
      ForceDirectories(sdir);

      sfile := sdir + 'BO.' + t.TableNameDelphi + '.pas';
      if FileExists(sfile) then
         ShowMessage(sfile + 'bestaat al.'+#13#10+'BO wordt niet aangemaakt.')
      else
      begin
         sdata := GenerateBOForTable(t);
         TFile.WriteAllText(sfile, sdata);
      end;
   finally
      btnGenerateBO.Enabled := True;
   end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  t: TCRUDTable;
  sdir, sfile,
  sdata, smodel: string;
  strCustomTypes: TStrings;
begin
  pbGenerate.Position := 0;
  pbGenerate.Visible  := True;
  btnGenerate.Enabled := False;
  strCustomTypes      := nil;
  try
    Self.Update;
    if TfrmMain.OutputCRUDPath = '' then
      TfrmMain.OutputCRUDPath := ExtractFilePath(Application.ExeName) + 'CRUDs\';
    sdir := TfrmMain.OutputCRUDPath;
    ForceDirectories(sdir);

    InitCircularDepsFix;

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

      if TGenerator.TablesWithSeperateModels.IndexOf(t.TableName) >= 0 then
      begin
        sdata := TGenerator.GenerateCRUDForTable(t, smodel);
        sfile := sdir + 'CRUD.' + t.TableName + '.pas';
        TFile.WriteAllText(sfile, sdata);
        sfile := sdir + 'Model.' + t.TableName + '.pas';
        TFile.WriteAllText(sfile, smodel);
      end
      else
      begin
        sdata := GenerateCRUDForTable(t);
        sfile := sdir + 'CRUD.' + t.TableName + '.pas';
        TFile.WriteAllText(sfile, sdata);
      end;

      sdata := GenerateMetaForTable(t);
      sfile := sdir + 'Meta.' + t.TableName + '.pas';
      TFile.WriteAllText(sfile, sdata);                   //todo: put "shared" metadata in seperate dir (for sharing between client and server without using/sharing cruds with client)
    end;

    strCustomTypes := GenerateCustomMetaTypesOfAllTables;
    sfile := sdir + 'Meta.CustomIDTypes.pas';
    strCustomTypes.SaveToFile(sfile);
  finally
    strCustomTypes.Free;
    pbGenerate.Visible := False;
    btnGenerate.Enabled := True;
  end;
end;

procedure TfrmMain.btnGenerateTableClick(Sender: TObject);
var
  t: TCRUDTable;
  sdir, sfile,
  sdata, smodel: string;
begin
  t := grdTables.Objects[0, grdTables.Row] as TCRUDTable;

  btnGenerateTable.Enabled := False;
  try
    if TfrmMain.OutputCRUDPath = '' then
      TfrmMain.OutputCRUDPath := ExtractFilePath(Application.ExeName) + 'CRUDs\';
    sdir := TfrmMain.OutputCRUDPath;
    ForceDirectories(sdir);

    if TGenerator.TablesWithSeperateModels.IndexOf(t.TableName) >= 0 then
    //if t.TableName = 'Relatie_T' then
    begin
      sdata := TGenerator.GenerateCRUDForTable(t, smodel);
      sfile := sdir + 'CRUD.' + t.TableNameDelphi + '.pas';
      TFile.WriteAllText(sfile, sdata);
      sfile := sdir + 'Model.' + t.TableNameDelphi + '.pas';
      TFile.WriteAllText(sfile, smodel);
    end
    else
    begin
      sdata := GenerateCRUDForTable(t);
      sfile := sdir + 'CRUD.' + t.TableNameDelphi + '.pas';
      TFile.WriteAllText(sfile, sdata);
    end;

    sdata := GenerateMetaForTable(t);
    sfile := sdir + 'Meta.' + t.TableNameDelphi + '.pas';
    TFile.WriteAllText(sfile, sdata);                   //todo: put "shared" metadata in seperate dir (for sharing between client and server without using/sharing cruds with client)

    with GenerateCustomMetaTypesOfAllTables do
    begin
      sfile := sdir + 'Meta.CustomIDTypes.pas';
      SaveToFile(sfile);
      Free;
    end;
  finally
    btnGenerateTable.Enabled := True;
  end;
end;

procedure TfrmMain.btnLoadTablesClick(Sender: TObject);
var
  connection: TBaseADOConnection;
  mssql: TMSSQLConnection;
  ds: TADODataSet;
  tbl: TCRUDTable;
  dbconn: TDBConfig;
begin
  grdTables.RowCount  := 1;
  grdTables.RowCount  := 2;
  grdTables.Cells[0, 0] := 'Tablename';
  grdTables.FixedRows := 1;

  dbconn := TDBSettings.Instance.GetDBConnection('', dbtNone);  //get specific settings or first in case no dbtype etc
  connection := TDBConnectionPool.GetConnectionFromPool(dbconn) as TBaseADOConnection;
  try
    Assert(connection is TMSSQLConnection);
    mssql := (connection as TMSSQLConnection);

    ds := TADODataset.Create(nil);
    try
      ds.Close;
      if mssql.IsSQLServerCE then
      begin
        //strange, does not work with SQL CE
        with TADOCommand.Create(nil) do
        try
          ConnectionString := mssql.ADOConnection.ConnectionString;
          CommandText := 'SELECT TABLE_TYPE, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES';
          ds.Recordset := Execute;
        finally
          Free;
        end
      end
      else
        mssql.ADOConnection.OpenSchema(siTables, EmptyParam, EmptyParam, ds);

      ds.First;
      while not ds.Eof do
      begin
        if (ds.FieldByName('TABLE_TYPE').AsString = 'TABLE') or
           (ds.FieldByName('TABLE_TYPE').AsString = 'VIEW') then
        begin
          tbl := CRUDSettings.FindTable(ds.FieldByName('TABLE_NAME').AsString, True{auto create});
          tbl.TableName  := ds.FieldByName('TABLE_NAME').AsString;

          grdTables.Cells  [0, grdTables.RowCount-1] := ds.FieldByName('TABLE_NAME').AsString;
          grdTables.Objects[0, grdTables.RowCount-1] := tbl;
          grdTables.RowCount := grdTables.RowCount + 1;
        end;

        ds.Next;
      end;
    finally
      ds.Free;
    end;
  finally
    TDBConnectionPool.PutConnectionToPool(dbconn, connection);
  end;

  grdTables.RowCount := grdTables.RowCount - 1;
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
var
  f: TCRUDField;
begin
  f := grdFields.Objects[0, grdFields.Row] as TCRUDField;
  f.SkipDefault := StrToBoolDef(cbbSkipDefault.Text, False);
  grdFields.Cells[grdFields.Col, grdFields.Row] := cbbSkipDefault.Text;
end;

procedure TfrmMain.cbbTypeCmbxSelect(Sender: TObject);
var
  f: TCRUDField;
begin
  f := grdFields.Objects[0, grdFields.Row] as TCRUDField;
  f.FieldType := cbbTypeCmbx.Text;
  grdFields.Cells[grdFields.Col, grdFields.Row] := cbbTypeCmbx.Text;
end;

procedure TfrmMain.cmbxCustomTypeSelect(Sender: TObject);
var
  f: TCRUDField;
begin
  f := grdFields.Objects[0, grdFields.Row] as TCRUDField;
  f.CustomType := cmbxCustomType.Text;
  grdFields.Cells[grdFields.Col, grdFields.Row] := cmbxCustomType.Text;
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
    mrNo : CanClose := True;
    mrCancel: Abort;
  end;
end;

function TfrmMain.GenerateCRUDForTable(const aTable: TCRUDTable): string;
begin
  Result := TGenerator.GenerateCRUDForTable(aTable);
end;

function TfrmMain.GenerateBOForTable(const aTable: TCRUDTable): string;
begin
  Result := TGenerator.GenerateBOForTable(aTable);
end;

function TfrmMain.GenerateCustomMetaTypesOfAllTables: TStrings;
begin
  Result := TGenerator.GenerateCustomMetaTypesOfAllTables;
end;

function TfrmMain.GenerateMetaForTable(const aTable: TCRUDTable): string;
begin
  Result := TGenerator.GenerateMetaForTable(aTable);
end;

procedure TfrmMain.grdFieldsGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
   case TGridField(ACol) of
      cFld_MinValue,
      cFld_MaxValue: Value := FloatToStr(StrToFloatDef(Value,0));
      cFld_DisplayWidth: Value := IntToStr(StrToIntDef(Value,0));
   end;
end;

procedure TfrmMain.grdFieldsSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  f: TCRUDField;

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

begin
  CanSelect := False;
  cmbxCustomType.Visible := False;
  cbbTypeCmbx.Visible := False;
  cbbSkipDefault.Visible := False;
  f := grdFields.Objects[0, ARow] as TCRUDField;

  case TGridField(ACol) of
     cFld_Type:
        SelectWithCombo(cbbTypeCmbx, f.FieldType);
     cFld_CustomType:
        SelectWithCombo(cmbxCustomType, f.CustomType);
     cFld_MinValue,
     cFld_MaxValue,
     cFld_Displaylabel,
     cFld_DisplayFormat,
     cFld_DisplayWidth,
     cFld_EditFormat,
     cFld_EditMask:
         CanSelect := True;
     cFld_SkipDefault:
     begin
       if f.HasDefault then
          SelectWithCombo(cbbSkipDefault, IfThen(f.SkipDefault, 'True', 'False'));
     end;
  end;

  if not CanSelect then
  begin
    grdFields.OnSelectCell := nil;
    grdFields.Row          := ARow;
    grdFields.Col          := C_GridFieldIndex[cFld_Displaylabel];
    grdFields.OnSelectCell := grdFieldsSelectCell;
  end;
end;

procedure TfrmMain.grdFieldsSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
var
  f: TCRUDField;
  s: string;
begin
  f := grdFields.Objects[0, ARow] as TCRUDField;

  case TGridField(ACol) of
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

procedure TfrmMain.grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  tbl: TCRUDTable;
begin
  tbl := grdTables.Objects[0, ARow] as TCRUDTable;
  LoadFields(tbl);
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
      if TGenerator.TablesWithSeperateModels.IndexOf(t.TableName) < 0 then
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

  if aTbl = nil then Exit;
  lblFields.Caption := 'Fields of: ' + aTbl.TableName;

  grdFields.RowCount  := 1;
  grdFields.FixedCols := 0;
  grdFields.ColCount  := Length(C_GridFieldIndex);

  FillFieldsForTable(aTbl);  //refresh
  grdFields.RowCount := aTbl.FieldCount + 1; //grdFields.FixedRows;
  grdFields.Row      := 0; //grdFields.FixedRows;

  for f in aTbl.Fields do
  begin
    grdFields.Row := grdFields.Row + 1;

    row := grdFields.Rows[grdFields.Row];
    row.Clear;
    row.AddObject(f.FieldName, f);
    row.Add( f.FieldType  );
    if (f.CustomType = '') and AutoCustomTypes.ContainsKey(f.FieldName)then
      f.CustomType := AutoCustomTypes.Items[f.FieldName];

    row.Add( f.CustomType );
    row.Add(BoolToStr(f.Required, True));
    if f.MaxValue > 0 then       //maxvalue filled? then show minvalue too
      row.Add(FloatToStr(f.MinValue))
    else
      row.Add('');
    if f.MaxValue > 0 then
      row.Add(FloatToStr(f.MaxValue))
    else
      row.Add('');
    if TGenerator.Vertaalbaar and (Trim(f.Displaylabel) = '') then
      f.Displaylabel := f.FieldName; // voor vertalingen -> moet een displaywaarde ingevuld zijn
    row.Add(f.Displaylabel);
    row.Add(f.DisplayFormat);
    if f.DisplayWidth > 0 then
      row.Add(IntToStr(f.DisplayWidth))
    else
      row.Add('');
    row.Add(f.EditFormat);
    row.Add(f.EditMask);
    row.Add(f.FKTable);
    row.Add(f.FKField);
    if f.HasDefault then
       row.Add(IfThen(f.SkipDefault, 'True','False'));
  end;

  row := grdFields.Rows[0];
  row.Clear;
  for GridField := Low(TGridField) to High(TGridField) do
  begin
    row.add(C_GridFieldName[GridField]);
    grdFields.ColWidths[C_GridFieldIndex[GridField]] := 90;
  end;

  grdFields.FixedRows := 1;
  grdFields.ColWidths[C_GridFieldIndex[cFld_Fieldname]] := 150;
  grdFields.ColWidths[C_GridFieldIndex[cFld_CustomType]] := 180;
  grdFields.ColWidths[C_GridFieldIndex[cFld_Required]] := 80;
  grdFields.ColWidths[C_GridFieldIndex[cFld_Displaylabel]] := 180;

  grdFields.OnSelectCell := grdFieldsSelectCell;
  grdFields.Col          := C_GridFieldIndex[cFld_Displaylabel];
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
  var
    lst: TList<TCRUDTable>;
    t: TCRUDTable;
  begin
    lst := deps.Items[aTable];        //aTable = Relatie_T
    for t in lst do
    begin
      if t = aTable then Continue;    //links to self are ok

      if not aDeps.Contains(t) then   //t = Email
      begin
        aDeps.Add(t);
        _GetAllDeps(t, aDeps);
      end;
    end;
  end;

  procedure _AddDeps(aTable: TCRUDTable);
  var
    lst, lst2: TList<TCRUDTable>;
    t2: TCRUDTable;
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
          if t2 = t then Continue;  //links to self are ok
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
   AutoCustomTypes  := TAutomaticCustomTypeList.Create;

finalization
   AutoCustomTypes.Free;

end.
