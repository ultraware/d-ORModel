unit uGenerator;

interface

uses
   Classes, SysUtils, Generics.Collections, Data.CRUDSettings;

type
  TProcedureReference = reference to procedure;
  TCustomCRUDGeneratorFunc = reference to function(const aTable: TCRUDTable): string; 
  TCustomCRUDDict = class(TDictionary<string,TCustomCRUDGeneratorFunc>);

  TGeneratorSettings = class
  private
    class var FTemplatePath: string;
    class var FUsesCommonCustomTypes: Boolean;
    class var FVertaalbaar: Boolean;
    class var FOutputCRUDAndMetaPath: string;
    class var FOnCreateTempTableDefs: TProcedureReference;
    class var FCustomCRUDDict: TCustomCRUDDict;
    class function GetOutputCRUDAndMetaPath: string; static;
    class function GetTemplatePath: string; static;
    class function GetOutputCustomIDTypesFile: string; static;
    class function GetOutputSettingsFile: string; static;
    class function GetCustomCRUDDIct: TCustomCRUDDict; static;
  public
    class destructor Destroy;
    class property Vertaalbaar: Boolean read FVertaalbaar write FVertaalbaar;
    class property UsesCommonCustomTypes: Boolean read FUsesCommonCustomTypes write FUsesCommonCustomTypes;

    class property TemplatePath: string read GetTemplatePath write FTemplatePath;
    class property OutputCRUDPath: string read GetOutputCRUDAndMetaPath write FOutputCRUDAndMetaPath;
    class property OutputMetaPath: string read GetOutputCRUDAndMetaPath write FOutputCRUDAndMetaPath;
    class property OutputCustomIDTypesFile: string read GetOutputCustomIDTypesFile;
    class property OutputSettingsFile: string read GetOutputSettingsFile;
    class property OnCreateTempTableDefs: TProcedureReference read FOnCreateTempTableDefs write FOnCreateTempTableDefs;
    class property CustomCRUDDict: TCustomCRUDDict read GetCustomCRUDDIct;
  end;

   TGenerator = class
   private
     class var FTablesWithSeperateModels: TStrings;
     class function InternalGenerateCRUDForTable(const aTable: TCRUDTable; const bGenerateSeperateModel: Boolean): Boolean; static;
   public
     class constructor Create;
     class destructor  Destroy;

     class function GenerateMetaForTable(const aTable: TCRUDTable): Boolean; static;
     class function GenerateCRUDForTable(const aTable: TCRUDTable): Boolean; static;
     class function GenerateModelForTable(const aTable: TCRUDTable): Boolean; static;
     class function GenerateCustomMetaTypesOfAllTables: Boolean;

     class procedure GetFieldInfo(const F: TCRUDField; const aTable: TCRUDTable; out sfieldtype, sAttr, sGetter: string; const MetaInAttribute: Boolean = False); static;      
     class property TablesWithSeperateModels: TStrings read FTablesWithSeperateModels;
   end;

implementation

uses
   TypInfo, StrUtils, Math, ADODB, Forms, IOUtils, Dialogs,
   Meta.Data, 
   DB.Connection.SQLServer, DB.Settings, DB.ConnectionPool,
   uMetaLoader, UltraStringUtils;

class procedure TGenerator.GetFieldInfo(const F: TCRUDField; const aTable: TCRUDTable; out sfieldtype, sAttr, sGetter: string; const MetaInAttribute: Boolean = False);
const C_FieldTypeName: array [Meta.Data.TFieldType] of string = ('Unknown', 'ID', 'String', 'Boolean', 'Double', 'Integer', 'DateTime', 'Currency');
var ftype: Meta.Data.TFieldType;
     str: string;
begin
   ftype := Meta.Data.TFieldType(TypInfo.GetEnumValue(TypeInfo(Meta.Data.TFieldType), f.FieldType));
   Assert(Ord(ftype) >= 0);
   if (f.CustomType <> '') then
   begin
      str := Copy(f.CustomType, 2, Length(f.CustomType)); // zonder T
      sGetter := Format('Get%s', [str]);
      sfieldtype := f.CustomType;
   end
   else
   if (ftype = ftFieldID) or ((ftype = ftFieldInteger) and (f.IsFK)) then
   begin
      if (ftype = ftFieldID) then
         str := aTable.TableName
      else
         str := f.FKTable;
      sGetter := Format('GetTyped%s_IDField', [str]);
      sfieldtype := Format('TTyped%s_IDField', [str]);
   end
   else
   begin
      str := C_FieldTypeName[ftype];
      sGetter := Format('Get%sField', [str]);
      sfieldtype := Format('TTyped%sField', [str]);
   end;

   if SameText(f.FieldNameDelphi, aTable.TableNameDelphi) then
      str := f.FieldNameDelphi + '_'
   else
      str := f.FieldNameDelphi;
   sAttr := Format('[%s(%s%s)]', [aTable.TableNameDelphi, ifthen(MetaInAttribute, Format('Meta.%s.', [aTable.TableNameDelphi])), str]);
end;

class function TGenerator.InternalGenerateCRUDForTable(const aTable: TCRUDTable; const bGenerateSeperateModel: Boolean): Boolean;
var str, strFields, sAutojoinData1, sAutojoinData2, sAutojoinFunctions, sAutojoinUses, sParamFunctions: TStrings;
  f: TCRUDField;
    sAttr, sfieldtype, sProperty, sGetter, sName, ExtraUses, sFileName, sOrigineel, sData: string;
  iNr: Integer;

   procedure SetTableFunctionParameters;

      function DataTypeToDelphiDataType(aType: string): string;
      begin
         if StringIn(aType, 'int,tinyint,smallint,ntext,numeric,bigint') then
            Result := 'Integer'
         else if StringIn(aType, 'text,varchar,nvarchar') then
            Result := 'string'
         else if StringIn(aType, 'real,float,decimal') then
            Result := 'Double'
         else if StringIn(aType, 'money,smallmoney') then
            Result := 'Currency'
         else if StringIn(aType, 'datetime,smalldatetime') then
            Result := 'TDateTime'
         else if StringIn(aType, 'date') then
            Result := 'TDate'
         else if StringIn(aType, 'timestamp') then
            Result := 'TTime'
         else if StringIn(aType, 'sql_variant') then
            Result := 'Variant'
         else if StringIn(aType, 'bit') then
            Result := 'Boolean'
         else if StringIn(aType, 'char,nchar') then
            Result := 'Char'
      end;

   var Connection: TBaseADOConnection;
       dbconn: TDBConfig;
       mssql: TMSSQLConnection;
       parameterName, procedureStr: string;
       ds: TADODataSet;
       index: Integer;
   begin
      dbconn := TDBSettings.Instance.GetDBConnection('', dbtNone); // get specific settings or first in case no dbtype etc
      Connection := TDBConnectionPool.GetConnectionFromPool(dbconn) as TBaseADOConnection;
      Assert(Connection is TMSSQLConnection);
      mssql := (Connection as TMSSQLConnection);
      ds := TADODataSet.Create(nil);
      ds.Close;

      with TADOCommand.Create(nil) do
      begin
         try
            ConnectionString := mssql.ADOConnection.ConnectionString;
            CommandText := 'SELECT replace(p.name, ''@'', '''') as ParameterName, t.name as DataType ' + 
                  'FROM sys.objects o ' +
                  '    inner join sys.parameters p on (p.object_id = o.object_id) ' + 
                  '    inner join sys.types t on (p.system_type_id = t.system_type_id) ' +
                  'WHERE o.Name = ' + QuotedStr(aTable.TableName) + ' '+
                  'Order by p.parameter_id';
            ds.Recordset := Execute;
         finally
            Free;
         end;
      end;

      ds.First;
      index := 0;
      strFields.Add('');
      while not ds.Eof do
      begin
         parameterName := Capitalize(ds.FieldByName('ParameterName').AsString);
         procedureStr := 'Set' + parameterName + '(const ' + parameterName + ': ' + DataTypeToDelphiDataType(ds.FieldByName('DataType').AsString) + ');';
         with sParamFunctions do
         begin
            Add('procedure T' + aTable.TableNameDelphi + '.' + procedureStr);
            Add('begin');
            Add('   GetFieldForID.SetTableParameter(' + parameterName + ', ' + IntToStr(index) + ');');
            Add('end;');
            Add('');
         end;
         strFields.Add('    procedure ' + procedureStr);

         Inc(index);
         ds.Next;
      end;
   end;

var CustomCRUDGeneratorFunc: TCustomCRUDGeneratorFunc;
begin
  sAutojoinData1 := nil;
  sAutojoinData2 := nil;
  sAutojoinFunctions := nil;
  sAutojoinUses := nil;
  ExtraUses := '';

  str := TStringList.Create;
  sParamFunctions := TStringList.Create;
  strFields := TStringList.Create;
  try
    if bGenerateSeperateModel then
      sFileName := aTable.ModelFileName
    else
      sFileName := aTable.CRUDFileName;
            
    if (not bGenerateSeperateModel) and TGeneratorSettings.CustomCRUDDict.TryGetValue(aTable.TableName, CustomCRUDGeneratorFunc) then
      sData := CustomCRUDGeneratorFunc(aTable)
    else
    begin    
      if TGeneratorSettings.UsesCommonCustomTypes then
         ExtraUses := ', Data.CommonCustomTypes';      
      if FileExists(sFileName) then
      begin
         str.LoadFromFile(sFileName);
         sOrigineel := str.Text;
         str.Clear;
      end
      else
         sOrigineel := '';

      str.LoadFromFile(TGeneratorSettings.TemplatePath + '\mcTemplateCRUD.inc');

    str.Text := StringReplace(str.Text, '%Uses%'   , ExtraUses, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);

    if bGenerateSeperateModel then
      str.Text := StringReplace(str.Text, '%TJoinableDataRecord%' , 'Model.' + aTable.TableNameDelphi + '.T' + aTable.TableNameDelphi, [rfReplaceAll])
    else
      str.Text := StringReplace(str.Text, '%TJoinableDataRecord%' , 'TJoinableDataRecord', [rfReplaceAll]);

         if (aTable.FieldCount = 0) then
      TMetaLoader.FillFieldsForTable(aTable);

    iNr := 0;
    for f in aTable.Fields do
    begin
      GetFieldInfo(f, aTable, sfieldtype, sAttr, sGetter);
      sProperty := Format('property  %-26s : %-25s  index %3d read %s;', [f.FieldNameDelphi, sfieldtype, iNr, sGetter]);
      Inc(iNr);

      strFields.Add(Format('%-45s  %s', [sAttr, sProperty]));
    end;

    //auto join child data (Bedrijf.Contactpersoon.Relatie etc)
    sAutojoinData1     := TStringList.Create;
    sAutojoinData2     := TStringList.Create;
    sAutojoinFunctions := TStringList.Create;
    sAutojoinUses      := TStringList.Create;

    if bGenerateSeperateModel then
      sAutojoinUses.Add('Model.' + aTable.TableNameDelphi);

    for f in aTable.Fields do
    begin
      if f.IsFK and (f.FKTable <> '') and (f.FKTable <> 'Object') and f.GenerateDirectJoin then
      begin
        if sAutojoinData1.Count = 0 then
        begin
          sAutojoinData1.Add(#13#10'  protected');
          sAutojoinData2.Add(#13#10'  public');
          sAutojoinFunctions.Add('{ T' + aTable.TableNameDelphi + ' }'#13);
        end;

        if FTablesWithSeperateModels.IndexOf(f.FKTable) >= 0 then
          sName := 'Model.' + f.FKTable
        else
          sName := 'CRUD.' + f.FKTable;
        if f.FKTable <> aTable.TableName then  //in case table has FK to itself
        if (sAutojoinUses.IndexOf(sName) < 0) and (sAutojoinUses.IndexOf(', ' + sName) < 0) then
        begin
          if sAutojoinUses.Count = 0 then
            sAutojoinUses.Add(sName)
          else
            sAutojoinUses.Add(', ' + sName);
        end;

        sName := Copy(f.FieldNameDelphi, 1, Pos('_ID', f.FieldNameDelphi)-1);  //remove last _ID part
        if sName = '' then
          sName := f.FieldNameDelphi + '_';   

        while (aTable.FindField(sName, False) <> nil) do
        begin
          sName := sName + '_';
        end;
        sAutojoinData1.Add('    F' + sName + ': T' + f.FKTable + ';');
        sAutojoinData2.Add('    function ' + sName + ': T' + f.FKTable + ';');
        //
        sAutojoinFunctions.Add('function T' + aTable.TableNameDelphi + '.' + sName + ': T' + f.FKTable + ';'#13'begin');
        sAutojoinFunctions.Add('  if F' + sName + ' = nil then '#13'  begin');
        sAutojoinFunctions.Add('    F' + sName + ' := T' + f.FKTable + '.Create(Self);');
        sAutojoinFunctions.Add('    F' + sName + '.ExternalJoinField := Self.' + f.FieldNameDelphi + ';');
        sAutojoinFunctions.Add('    F' + sName + '.OwnJoinField      := F' + sName + '.ID;');
        sAutojoinFunctions.Add('    AddChildData(F' + sName + ');'#13'  end;');
        sAutojoinFunctions.Add('  Result := F' + sName + ';'#13'end;'#13);
      end;
    end;

    if (aTable.TableFunctionParameterCount > 0) then
      SetTableFunctionParameters;

    if sAutojoinUses.Count > 0 then
    begin
      sAutojoinUses.LineBreak := '';
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildUses%', ','#13'  ' + Trim(sAutojoinUses.Text), []);
    end
    else
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildUses%', '', []);

    if (sAutojoinData1.Count > 0) then
    begin
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildData%', #13'  ' + Trim(sAutojoinData1.Text) + #13'  ' + Trim(sAutojoinData2.Text), []);
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildDataFunctions%', #13 + Trim(sAutojoinFunctions.Text) + #13, []);
    end
    else
    begin
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildData%', '', []);
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildDataFunctions%', '', []);
    end;

    if not bGenerateSeperateModel then
      str.Text := StringReplace(str.Text, '%DataPropertyFields%', Trim(strFields.Text), [rfReplaceAll])
    else
      str.Text := StringReplace(str.Text, '%DataPropertyFields%', '//see Model.' + aTable.TableNameDelphi + '.pas', [rfReplaceAll]);

    str.Text := StringReplace(str.Text, '%DataSetParamFunctions%', sParamFunctions.Text, []);

    if bGenerateSeperateModel then
    begin
      str.LoadFromFile(TGeneratorSettings.TemplatePath + '\mcTemplateCRUDModel.inc');

      str.Text := StringReplace(str.Text, '%Uses%'   , ExtraUses, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%DataPropertyFields%', Trim(strFields.Text), [rfReplaceAll]);
    end;

    sData := str.Text;
   end;

   Result := (not SameText(sData, sOrigineel));
   if Result then
     TFile.WriteAllText(sFileName, sData);
  finally
    strFields.Free;
    str.Free;
    sAutojoinData1.Free;
    sAutojoinData2.Free;
    sAutojoinFunctions.Free;
    sAutojoinUses.Free;
    sParamFunctions.Free;
  end;
end;

class function TGenerator.GenerateCRUDForTable(const aTable: TCRUDTable): Boolean;
begin
   Result := InternalGenerateCRUDForTable(aTable, False);
end;

class constructor TGenerator.Create;
begin
  FTablesWithSeperateModels := TStringList.Create;
end;

class destructor TGenerator.Destroy;
begin
  FTablesWithSeperateModels.Free;
end;

class function TGenerator.GenerateModelForTable(const aTable: TCRUDTable): Boolean;
begin
   Result := InternalGenerateCRUDForTable(aTable, True);
end;

class function TGenerator.GenerateCustomMetaTypesOfAllTables: Boolean;
var strCustomTypes: TStrings;
    sFileName, sOrgineelTxt: string;
  t: TCRUDTable;
begin
   sFileName := TGeneratorSettings.OutputCustomIDTypesFile;
  strCustomTypes := TStringList.Create;
   if FileExists(sFileName) then
   begin
      strCustomTypes.LoadFromFile(sFileName);
      sOrgineelTxt := strCustomTypes.Text;
      strCustomTypes.Clear;
   end
   else
      sOrgineelTxt := '';

  strCustomTypes.Add('unit Meta.CustomIDTypes;');
  strCustomTypes.Add('');
  strCustomTypes.Add('interface');
  strCustomTypes.Add('');
  strCustomTypes.Add('uses');
  strCustomTypes.Add('  Data.DataRecord;');
  strCustomTypes.Add('');
  strCustomTypes.Add('type');

  for t in CRUDSettings.Tables do
  begin
    if t.IsDataBaseTable then
    begin
      strCustomTypes.Add(Format('  T%s_ID = type TBaseIDValue;',[t.TableName])                     );
      strCustomTypes.Add(Format('  TTyped%s_IDField = class(TCustomIDField<T%0:s_ID>);',[t.TableName]) );
    end;
  end;

  strCustomTypes.Add('');
  strCustomTypes.Add('  TDataRecord_Helper = class helper for TDataRecord');
  strCustomTypes.Add('  protected');
  for t in CRUDSettings.Tables do
  begin
    if t.IsDataBaseTable then
      strCustomTypes.Add(Format('    function GetTyped%s_IDField(aIndex: Integer): TTyped%0:s_IDField;',[t.TableName]) );
  end;
  strCustomTypes.Add('  end;');

  strCustomTypes.Add('');
  strCustomTypes.Add('implementation');
  strCustomTypes.Add('');
  strCustomTypes.Add('{ TDataRecord_Helper }');
  strCustomTypes.Add('');

  for t in CRUDSettings.Tables do
  begin
    if t.IsDataBaseTable then
    begin
      strCustomTypes.Add(Format('function TDataRecord_Helper.GetTyped%s_IDField(aIndex: Integer): TTyped%0:s_IDField;',[t.TableName]) );
      strCustomTypes.Add(       'begin');
      strCustomTypes.Add(Format('  Result := GetTypedField<TTyped%s_IDField>(aIndex);',[t.TableName]) );
      strCustomTypes.Add(       'end;');
      strCustomTypes.Add('');
    end;
  end;

  strCustomTypes.Add('end.');
  Result := not SameText(strCustomTypes.Text, sOrgineelTxt);
  if Result then
    TFile.WriteAllText(sFileName, strCustomTypes.Text);
end;

class function TGenerator.GenerateMetaForTable(const aTable: TCRUDTable): Boolean;
var str, strTemplate: TStrings;
  f: TCRUDField;
    sAttr, sClass, ExtraUses, sFileName, sOrigineelText: string;
    UseExtraStamUses: Boolean;

  function GenerateDisplayLabeltext(const Field: TCRUDField): string;
  begin
    if TGeneratorSettings.Vertaalbaar then
      Result := 'TranslateString('+QuotedStr(Field.Displaylabel)+')' // Dit zorgt ervoor dat tekst wordt opgepikt door vertaalEngine
    else
      Result := QuotedStr(Field.Displaylabel);
  end;

begin
  str := TStringList.Create;
  strTemplate := TStringList.Create;
  UseExtraStamUses := False;
  try
    sFileName := aTable.MetaFileName;
    if FileExists(sFileName) then
    begin
      strTemplate.LoadFromFile(sFileName);
      sOrigineelText := strTemplate.Text;
      strTemplate.Clear;
    end
    else
      sOrigineelText := '';

    strTemplate.LoadFromFile(TGeneratorSettings.TemplatePath + '\mcTemplateMetaData.inc');

    strTemplate.Text := StringReplace(strTemplate.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    strTemplate.Text := StringReplace(strTemplate.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    strTemplate.Text := StringReplace(strTemplate.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);

    str.Add(Format('  T%sField      = class(TBaseTableField);', [aTable.TableNameDelphi]));
    str.Add(Format('  T%sFieldClass = class of T%sField;', [aTable.TableNameDelphi, aTable.TableNameDelphi]));
    str.Add('');

    str.Add('  {$RTTI INHERIT}');       //inherit

    if (aTable.TableFunctionParameterCount > 0) then
      str.Add(Format('  [TFunctionTableMeta(%s, %d)]', // todo: also table type? e.g. table, view
         [QuotedStr(aTable.TableName), aTable.TableFunctionParameterCount]))
    else
      str.Add(Format('  [TTableMeta(%s)]', // todo: also table type? e.g. table, view
         [QuotedStr(aTable.TableName)]));

    str.Add(Format('  %s = class(TBaseTableAttribute)',[aTable.TableNameDelphi]));
    str.Add(       '  public');
    str.Add(Format('    constructor Create(const aField: T%sFieldClass);',[aTable.TableNameDelphi]));
    str.Add(       '  end;');
    str.Add('');

    if aTable.FieldCount = 0 then
      TMetaLoader.FillFieldsForTable(aTable);

    //iNr := 0;
    for f in aTable.Fields do
    begin
      //if f.FieldType in [ftFieldID] then
      begin
        sAttr := Format('  [%-18s(%s, %s, %s, %s', //)]',
                        [TTypedMetaField.ClassName,
                         QuotedStr(f.FieldName),
                         f.FieldType,
                         IfThen(f.Required, 'True{required}', 'False'),
                         GenerateDisplayLabeltext(f)]);
        sAttr := sAttr + ', ' + StringReplace(FloatToStr(f.MinValue), ',', '.', []);
        sAttr := sAttr + ', ' + StringReplace(FloatToStr(f.MaxValue), ',', '.', []);
        sAttr := sAttr + ', ' + QuotedStr(f.DisplayFormat);
        sAttr := sAttr + ', ' + IntToStr(f.DisplayWidth);
        sAttr := sAttr + ', ' + QuotedStr(f.EditFormat);
        sAttr := sAttr + ', ' + QuotedStr(f.EditMask);

        //strip empty optional values
        if EndsStr(', 0, '''', 0, '''', ''''', sAttr) then
          sAttr := Copy(sAttr, 1, Length(sAttr) - Length(', 0, '''', 0, '''', '''''));

        sAttr := sAttr + ')]';
      end;

      if f.IsPK then
        //[TPKMetaField]
        str.Add( Format('  [%s(%s)]', [TPKMetaField.ClassName, IfThen(f.IsAutoInc, 'True{autoinc}', 'False{no autoinc}')]) );
      if f.IsFK then
        //[TFKMetaField]
        str.Add(Format('  [%s(''%s'', ''%s'')]', [TFKMetaField.ClassName, f.FKTable, f.FKField]) );

      if f.HasDefault and (not f.SkipDefault) then
      begin
        str.Add(Format('  [%-18s(%s)]', [TDefaultValueMeta.ClassName, QuotedStr(f.DefaultValue)]));
      end;

      if SameText(f.FieldNameDelphi, aTable.TableNameDelphi) then                    //Gegegeven tabel met Gegegeven veld...
        sClass := Format('    %-20s  = class(T%sField);', [f.FieldNameDelphi + '_', aTable.TableNameDelphi])
      else
        sClass := Format('    %-20s  = class(T%sField);', [f.FieldNameDelphi, aTable.TableNameDelphi]);
      str.Add( Format('%-90s   %s', [sAttr, sClass]) );
    end;

    ExtraUses := '';
    if TGeneratorSettings.Vertaalbaar then
      ExtraUses := ExtraUses + ', UltraStringUtils';

    //fill template
    strTemplate.Text := StringReplace(strTemplate.Text, '%Uses%'   , ExtraUses, [rfReplaceAll]);
    strTemplate.Text := StringReplace(strTemplate.Text, '%interface%', str.Text, [rfReplaceAll]);

    str.Clear;
    str.Add(Format('constructor %s.Create(const aField: T%sFieldClass);',[aTable.TableNameDelphi, aTable.TableNameDelphi]));
    str.Add(       'begin');
    str.Add(       '  FField := aField;');
    str.Add(       'end;');

    //fill templace
    strTemplate.Text := StringReplace(strTemplate.Text, '%implementation%', str.Text,    [rfReplaceAll]);

    Result := not SameText(strTemplate.Text, sOrigineelText);
    if Result then
      TFile.WriteAllText(sFileName, strTemplate.Text);
  finally
    strTemplate.Free;
    str.Free;
  end;
end;

{ TGeneratorSettings }

class destructor TGeneratorSettings.Destroy;
begin
   FCustomCRUDDict.Free;
   inherited;
end;

class function TGeneratorSettings.GetCustomCRUDDIct: TCustomCRUDDict;
begin
   if (not Assigned(FCustomCRUDDict)) then
      FCustomCRUDDict := TCustomCRUDDict.Create;
   Result := FCustomCRUDDict;
end;

class function TGeneratorSettings.GetTemplatePath: string;
begin
   Result := FTemplatePath;
   if (Result = '') then
   begin
      FTemplatePath := '..\..\templates\';
      Result := FTemplatePath;
   end;
end;

class function TGeneratorSettings.GetOutputCRUDAndMetaPath: string;
begin
   Result := FOutputCRUDAndMetaPath;
   if (Result = '') then
   begin
      FOutputCRUDAndMetaPath := ExtractFilePath(Application.ExeName) + 'CRUDs\';
      Result := FOutputCRUDAndMetaPath;
   end;
   ForceDirectories(Result);
end;

class function TGeneratorSettings.GetOutputCustomIDTypesFile: string;
begin
   Result := OutputCRUDPath + 'Meta.CustomIDTypes.pas';
end;

class function TGeneratorSettings.GetOutputSettingsFile: string;
begin
   Result := OutputCRUDPath + cCRUDSettings_XML;
end;

initialization
  TGeneratorSettings.Vertaalbaar := False;
  TGeneratorSettings.UsesCommonCustomTypes := False;

end.
