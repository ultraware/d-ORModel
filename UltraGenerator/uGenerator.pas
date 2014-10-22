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
unit uGenerator;

interface

uses
  Classes,
  Data.CRUDSettings;

type
  TGenerator = class
  private
    class var FTemplatePath: string;
    class var FTablesWithSeperateModels: TStrings;
    class var FVertaalbaar: Boolean;
    class var FUsesCommonCustomTypes: Boolean;
    class function InternalGenerateCRUDForTable(const aTable: TCRUDTable; bGenerateSeperateModel: boolean; out aSeperateModel: string): string;
  public
    class constructor Create;
    class destructor  Destroy;

    class function GenerateMetaForTable(const aTable: TCRUDTable): string; static;
    class function GenerateCRUDForTable(const aTable: TCRUDTable): string; overload;
    class function GenerateCRUDForTable(const aTable: TCRUDTable; out aSeperateModel: string): string; overload;
    class function GenerateBOFOrTable(const aTable: TCRUDTable): string;
    class function GenerateCustomMetaTypesOfAllTables: TStrings;

    class property TemplatePath: string read FTemplatePath write FTemplatePath;
    class property TablesWithSeperateModels: TStrings read FTablesWithSeperateModels;
    class property Vertaalbaar: Boolean read FVertaalbaar write FVertaalbaar;
    class property UsesCommonCustomTypes: Boolean read FUsesCommonCustomTypes write FUsesCommonCustomTypes;
  end;

implementation

uses
  SysUtils, Variants, TypInfo, StrUtils,
  uMetaLoader, Meta.Data;
                                           
const
  C_FieldTypeName: array[Meta.Data.TFieldType] of string =
  ( 'Unknown', 'ID', 'String', 'Boolean', 'Double', 'Integer', 'DateTime', 'Currency' );

class function TGenerator.InternalGenerateCRUDForTable(
  const aTable: TCRUDTable; bGenerateSeperateModel: boolean; out aSeperateModel: string): string;
var
  str, strFields, sAutojoinData1, sAutojoinData2, sAutojoinFunctions, sAutojoinUses: TStrings;
  f: TCRUDField;
  ftype: Meta.Data.TFieldType;
  sAttr, sType, sfieldtype, sProperty, sGetter, sName: string;
  iNr: Integer;
  ExtraUses: string;
begin
  sAutojoinData1 := nil;
  sAutojoinData2 := nil;
  sAutojoinFunctions := nil;
  sAutojoinUses := nil;
  ExtraUses := '';

  str := TStringList.Create;

  if UsesCommonCustomTypes then
     ExtraUses := ', Data.CommonCustomTypes';
  strFields := TStringList.Create;
  try
    if TemplatePath = '' then
      TemplatePath := '..\..\templates\';
    str.LoadFromFile(TemplatePath + '\mcTemplateCRUD.inc');

    str.Text := StringReplace(str.Text, '%Uses%'   , ExtraUses, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    str.Text := StringReplace(str.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);
//    str.Text := StringReplace(str.Text, '%Database%'    , aTable.Database,  [rfReplaceAll]);
    if bGenerateSeperateModel then
      //Model.Relatie_T.TRelatie_T
      str.Text := StringReplace(str.Text, '%TJoinableDataRecord%' , 'Model.' + aTable.TableNameDelphi + '.T' + aTable.TableNameDelphi, [rfReplaceAll])
    else
      str.Text := StringReplace(str.Text, '%TJoinableDataRecord%' , 'TJoinableDataRecord', [rfReplaceAll]);

    if aTable.FieldCount = 0 then
      TMetaLoader.FillFieldsForTable(aTable);

    iNr := 0;
    for f in aTable.Fields do
    begin
      if SameText(f.FieldNameDelphi, aTable.TableNameDelphi) then
        sAttr   := Format('    [%s(%s)]', [aTable.TableNameDelphi, f.FieldNameDelphi + '_'])  //Gegegeven tabel met Gegegeven veld...
      else
        sAttr   := Format('    [%s(%s)]', [aTable.TableNameDelphi, f.FieldNameDelphi]);

      ftype := Meta.Data.TFieldType(TypInfo.GetEnumValue(TypeInfo(Meta.Data.TFieldType), f.FieldType));
      Assert(Ord(ftype) >= 0);
      sType := C_FieldTypeName[ftype];
      //GetTyped...Field
      if ftype = ftFieldID then
      begin
        sGetter    := format('GetTyped%s_IDField', [aTable.TableName]);
        sfieldtype := format('TTyped%s_IDField', [aTable.TableName]);
      end
      else if (ftype = ftFieldInteger) and
              (f.IsFK) then
      begin
        sGetter    := format('GetTyped%s_IDField', [f.FKTable]);
        sfieldtype := format('TTyped%s_IDField', [f.FKTable]);
      end
      else
      begin
        sGetter := format('Get%sField', [sType]);
        sfieldtype := 'TTyped' + sType + 'Field';
      end;

      if f.CustomType <> '' then
      begin
        sType   := Copy(f.CustomType, 2, Length(f.CustomType));
        sGetter := format('Get%s', [sType]);
        sfieldtype := f.CustomType;
      end;

      sProperty  := Format('property  %-26s : %-25s  index %3d read %s;'
                          ,[f.FieldNameDelphi, sfieldtype, iNr, sGetter]);
      inc(iNr);

      strFields.Add(Format('%-45s  %s', [sAttr, sProperty]));
    end;

    if not bGenerateSeperateModel then
      str.Text := StringReplace(str.Text, '%DataPropertyFields%',  trim(strFields.Text), [rfReplaceAll])
    else
      str.Text := StringReplace(str.Text, '%DataPropertyFields%',  '//see Model.' + aTable.TableNameDelphi + '.pas', [rfReplaceAll]);

    //auto join child data (Bedrijf.Contactpersoon.Relatie etc)
    sAutojoinData1     := TStringList.Create;
    sAutojoinData2     := TStringList.Create;
    sAutojoinFunctions := TStringList.Create;
    sAutojoinUses      := TStringList.Create;

    if bGenerateSeperateModel then
      //Model.Relatie_T
      sAutojoinUses.Add('Model.' + aTable.TableNameDelphi);

    for f in aTable.Fields do
    begin
      if f.IsFK and (f.FKTable <> '') and
         (f.FKTable <> 'Object') and
         f.GenerateDirectJoin then
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
        //indien niet eindigd met _ID
        if sName = '' then
          sName := f.FieldNameDelphi + '_';   //_ voor unieke naam

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

    if sAutojoinUses.Count > 0 then
    begin
      sAutojoinUses.LineBreak := '';
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildUses%', ','#13'  ' + Trim(sAutojoinUses.Text), []);
    end
    else
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildUses%', '', []);

    if (sAutojoinData1.Count > 0) then
    begin
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildData%', #13'  ' + Trim(sAutojoinData1.Text) +
                                                                     #13'  ' + Trim(sAutojoinData2.Text), []);
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildDataFunctions%', #13 + Trim(sAutojoinFunctions.Text) + #13, []);
    end
    else
    begin
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildData%', '', []);
      str.Text := StringReplace(str.Text, '%DataAutoJoinChildDataFunctions%', '', []);
    end;

    Result := str.Text;

    if bGenerateSeperateModel then
    begin
      str.LoadFromFile(TemplatePath + '\mcTemplateCRUDModel.inc');

      str.Text := StringReplace(str.Text, '%Uses%'   , ExtraUses, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%DataPropertyFields%',  trim(strFields.Text), [rfReplaceAll]);
      aSeperateModel := str.Text;
    end;

  finally
    strFields.Free;
    str.Free;
    sAutojoinData1.Free;
    sAutojoinData2.Free;
    sAutojoinFunctions.Free;
    sAutojoinUses.Free;
  end;
end;

class function TGenerator.GenerateCRUDForTable(
  const aTable: TCRUDTable): string;
var s: string;
begin
  Result := InternalGenerateCRUDForTable(aTable, False, s);
end;

class constructor TGenerator.Create;
begin
  FTablesWithSeperateModels := TStringList.Create;
end;

class destructor TGenerator.Destroy;
begin
  FTablesWithSeperateModels.Free;
end;

class function TGenerator.GenerateBOFOrTable(const aTable: TCRUDTable): string;
var
  Str, DataProperties, GetterDeclarations, PropertyDeclarations, Getters: TStringList;
  f: TCRUDField;
  ftype: Meta.Data.TFieldType;
  sAttr, sType, sfieldtype, sProperty, sGetter, sFieldName: string;
  iNr: Integer;
  ExtraUses: string;
begin
   ExtraUses := '';

   if UsesCommonCustomTypes then
      ExtraUses := ', Data.CommonCustomTypes';
   GetterDeclarations := TStringList.Create;
   PropertyDeclarations := TStringList.Create;
   Getters := TStringList.Create;
   Str := TStringList.Create;
   DataProperties := TStringList.Create;
   try
      if TemplatePath = '' then
         TemplatePath := '..\..\templates\';
      str.LoadFromFile(TemplatePath + '\mcTemplateBO.inc');

      str.Text := StringReplace(str.Text, '%Uses%', ExtraUses, [rfReplaceAll]);
      str.Text := StringReplace(str.Text, '%TableName%', aTable.TableNameDelphi, [rfReplaceAll]);

      if aTable.FieldCount = 0 then
         TMetaLoader.FillFieldsForTable(aTable);

      iNr := 0;
      for f in aTable.Fields do
      begin
         if SameText(f.FieldNameDelphi, aTable.TableNameDelphi) then
            sFieldName := f.FieldNameDelphi + '_'
         else
            sFieldName := f.FieldNameDelphi;
         sAttr := Format('      [%s(%s)]', [aTable.TableNameDelphi, sFieldName]);

         ftype := Meta.Data.TFieldType(TypInfo.GetEnumValue(TypeInfo(Meta.Data.TFieldType), f.FieldType));
         Assert(Ord(ftype) >= 0);
         sType := C_FieldTypeName[ftype];
         // GetTyped...Field
         if ftype = ftFieldID then
         begin
            sGetter := Format('GetTyped%s_IDField', [aTable.TableNameDelphi]);
            sfieldtype := Format('TTyped%s_IDField', [aTable.TableNameDelphi]);
         end
         else if (ftype = ftFieldInteger) and (f.IsFK) then
         begin
            sGetter := Format('GetTyped%s_IDField', [f.FKTable]);
            sfieldtype := Format('TTyped%s_IDField', [f.FKTable]);
         end
         else
         begin
            sGetter := Format('Get%sField', [sType]);
            sfieldtype := 'TTyped' + sType + 'Field';
         end;

         if f.CustomType <> '' then
         begin
            sType := Copy(f.CustomType, 2, Length(f.CustomType));
            sGetter := Format('Get%s', [sType]);
            sfieldtype := f.CustomType;
         end;

         sProperty := Format('property  %-26s : %-25s  index %3d read %s;', [f.FieldNameDelphi, sfieldtype, iNr, sGetter]);
         inc(iNr);

         DataProperties.Add(Format('%-45s  %s', [sAttr, sProperty]));
         GetterDeclarations.Add(Format('      function  Get%-26s : %s;',[sFieldname, sfieldtype]));
         PropertyDeclarations.Add(Format('      property  %-26s : %-25s read Get%s;',[sFieldname, sfieldtype, sFieldName]));

         Getters.Add(Format('function TBO%s.Get%s: %s;',[aTable.TableNameDelphi, sFieldName, sFieldType]));
         Getters.Add('begin');
         Getters.Add(Format('   Result := Meta.%s;',[sFieldName]));
         Getters.Add('end;');
         Getters.Add('');
      end;

      Str.Text := StringReplace(Str.Text, '%DataPropertyFields%',  trim(DataProperties.Text), [rfReplaceAll]);
      Str.Text := StringReplace(Str.Text, '%PropertyGetterDeclarations%',  trim(GetterDeclarations.Text), [rfReplaceAll]);
      Str.Text := StringReplace(Str.Text, '%PropertyDeclarations%',  trim(PropertyDeclarations.Text), [rfReplaceAll]);
      Str.Text := StringReplace(Str.Text, '%PropertyGetters%',  trim(Getters.Text), [rfReplaceAll]);
      Result := Str.Text;
   finally
      GetterDeclarations.Free;
      PropertyDeclarations.Free;
      Getters.Free;
      Str.Free;
      DataProperties.Free;
   end;
end;

class function TGenerator.GenerateCRUDForTable(const aTable: TCRUDTable;
  out aSeperateModel: string): string;
begin
  Result := InternalGenerateCRUDForTable(aTable, True, aSeperateModel);
end;

class function TGenerator.GenerateCustomMetaTypesOfAllTables: TStrings;
var
  strCustomTypes: TStrings;
  t: TCRUDTable;
begin
  strCustomTypes := TStringList.Create;

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
    strCustomTypes.Add(Format('  T%s_ID = type TBaseIDValue;',[t.TableName])                     );
    strCustomTypes.Add(Format('  TTyped%s_IDField = class(TCustomIDField<T%0:s_ID>);',[t.TableName]) );
  end;

  strCustomTypes.Add('');
  strCustomTypes.Add('  TDataRecord_Helper = class helper for TDataRecord');
  strCustomTypes.Add('  protected');
  for t in CRUDSettings.Tables do
  begin
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
    strCustomTypes.Add(Format('function TDataRecord_Helper.GetTyped%s_IDField(aIndex: Integer): TTyped%0:s_IDField;',[t.TableName]) );
    strCustomTypes.Add(       'begin');
    strCustomTypes.Add(Format('  Result := GetTypedField<TTyped%s_IDField>(aIndex);',[t.TableName]) );
    strCustomTypes.Add(       'end;');
    strCustomTypes.Add('');
  end;

  strCustomTypes.Add('end.');
  Result := strCustomTypes;
end;

class function TGenerator.GenerateMetaForTable(const aTable: TCRUDTable): string;
var
  str, strTemplate: TStrings;
  f: TCRUDField;
  sAttr, sClass: string;

  function IfThen(AValue: Boolean; const ATrue: string; const AFalse: string): string;
  begin
    if Avalue then
      Result := ATrue
    else
      Result := AFalse
  end;

  function GenerateDisplayLabeltext(const Field: TCRUDField): string;
  begin
   if Vertaalbaar then
     Result := 'TranslateString('+QuotedStr(Field.Displaylabel)+')' // Dit zorgt ervoor dat tekst wordt opgepikt door vertaalEngine
   else
      Result := QuotedStr(Field.Displaylabel);
  end;

var ExtraUses: string;
begin
  str := TStringList.Create;
  strTemplate := TStringList.Create;
  try
    if TemplatePath = '' then
      TemplatePath := '..\..\templates\';
    strTemplate.LoadFromFile(TemplatePath + '\mcTemplateMetaData.inc');

    strTemplate.Text := StringReplace(strTemplate.Text, '%UnitName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    strTemplate.Text := StringReplace(strTemplate.Text, '%TableName%'   , aTable.TableNameDelphi, [rfReplaceAll]);
    strTemplate.Text := StringReplace(strTemplate.Text, '%DBTableName%' , aTable.TableName, [rfReplaceAll]);
//    strTemplate.Text := StringReplace(strTemplate.Text, '%Database%'    , aTable.Database,  [rfReplaceAll]);

    str.Add( Format('  T%sField      = class(TBaseTableField);',
                    [aTable.TableNameDelphi]) );
    str.Add( Format('  T%sFieldClass = class of T%sField;',
                    [aTable.TableNameDelphi, aTable.TableNameDelphi]) );
    str.Add('');
    str.Add( Format('  [TTableMeta(%s)]',       //todo: also table type? e.g. table, view
                    [QuotedStr(aTable.TableName)])
           );

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
        //'  [TTypedMetaField   (''Status'', ftFieldInteger, True{required}, '''', 0, '''', 0, '''', '''')]'
        if EndsStr(', 0, '''', 0, '''', ''''', sAttr) then
          sAttr := Copy(sAttr, 1, Length(sAttr) - Length(', 0, '''', 0, '''', '''''));

        sAttr := sAttr + ')]';
      end;

      if f.IsPK then
        //[TPKMetaField]
                 str.Add( Format('  [%s]', [TPKMetaField.ClassName]) );
      if f.IsFK then
        //[TFKMetaField]
                 str.Add(Format('  [%s(''%s'', ''%s'')]', [TFKMetaField.ClassName, f.FKTable, f.FKField]) );

     if f.HasDefault and (not f.SkipDefault) then
      begin
        str.Add( Format('  [%-18s(%s)]',
                        [TDefaultValueMeta.ClassName,
                         QuotedStr(f.DefaultValue)]) );
      end;

      if SameText(f.FieldNameDelphi, aTable.TableNameDelphi) then                    //Gegegeven tabel met Gegegeven veld...
        sClass := Format('    %-20s  = class(T%sField);',
                        [f.FieldNameDelphi + '_', aTable.TableNameDelphi])
      else
        sClass := Format('    %-20s  = class(T%sField);',
                        [f.FieldNameDelphi, aTable.TableNameDelphi]);
      str.Add( Format('%-90s   %s', [sAttr, sClass]) );
    end;

    ExtraUses := '';
    if VertaalBaar then
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

    Result := strTemplate.Text;
  finally
    strTemplate.Free;
    str.Free;
  end;
end;

initialization
  TGenerator.Vertaalbaar := False;
  TGenerator.UsesCommonCustomTypes := False;

end.
