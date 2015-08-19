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
unit DB.SQLBuilder;

interface

uses // Delphi
  Data.Base, Data.DataRecord, Data.Query, DB.Settings;

type
  TSQLBuilder = class
  private
      class function GetDatabasePrefix(const aField: TBaseField; const aDefaultDatabase: string; dbConType: TDBConnectionType = dbtSQLServer): string;
      class function RemoveExtraEnters(const aSQL: string): string;
      class function IndentSQL(const aSQL: string): string;
      class function GetTableNameAndAlias(const aQuery: IQueryDetails; const aField: TBaseField; const aDefaultDatabase: string; dbConType: TDBConnectionType): string; static;
  protected
    class function GetTableHints(aTableHints: TTableHints): string;
    class function GetDatabaseName(const aField: TBaseField): string; overload;
    class function GetDatabaseName(const aDBNameType: string): string; overload;

    class function GetHavingByPart(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string;
    class function GetWherePart   (const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string; overload;
    class function GetWherePart   (const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; wheres: TWherePartList; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string; overload;
    class function GetJoinPart    (const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer): string;
    class function GetOrderByPart (const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer): string;
    class function GetGroupByPart (const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer): string;

      class function GetPreValidationCheck(const aQuery: IQueryDetails; aField: TBaseField; aStopOnError: Boolean = True): string;

      class function GenerateSelect(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType; const aMaxRecords: Integer = -1; const IsCTE: Boolean = False): string;
      class function GenerateInsert(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray;
         const dbConType: TDBConnectionType): string;
      class function GenerateUpdate(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray;
         const dbConType: TDBConnectionType): string;
      class function GenerateDelete(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray;
         const dbConType: TDBConnectionType): string;
  public
      class function GenerateSQL(const aDefaultDB: string; const aQuery: IQueryDetails; out aParams: TVariantArray; aMaxRecords: Integer = -1;
         dbConType: TDBConnectionType = dbtSQLServer): string;
    class function GenerateValidationSQL(const aQuery: IQueryDetails): string;
    class function GenerateCreateTableSQL(const aTableModel: TDataRecord; Withprimarykey: Boolean = True; DropTableIfExists: Boolean = False): string;
      class function GetFieldSQLWithAlias(const aQuery: IQueryDetails; const aField: TBaseField; const dbConType: TDBConnectionType; var aParams: TVariantArray; const WithAlias: Boolean = True): string;
  end;

implementation

uses // Delphi
     Variants, SysUtils, strUtils, math, Meta.Data{, DB.Connector}, TypInfo, Data.CRUD, Data.CustomSQLFields,
     // Shared
     UltraUtilsBasic;

{ TSQLBuilder }

type
  TBaseField_Ext = class(TBaseField);

class function TSQLBuilder.GenerateCreateTableSQL(const aTableModel: TDataRecord; Withprimarykey: Boolean = True; DropTableIfExists: Boolean = False): string;
var
   stable: string;
   f: TBaseField;
   fk: TFKMetaField;
   i: Integer;
   komma: string;
   StringSize: Integer;
begin
   stable := // GetDatabaseName(aTableModel.First) + '..' +
      aTableModel.First.TableName;

   (*
     CREATE TABLE ACTIONS2(
     ID int IDENTITY(1,1) NOT NULL,
     DESCRIPTION varchar(50) NULL,
     CONSTRAINT PK_ACTIONS2 PRIMARY KEY (ID)
     )
   *)
   if DropTableIfExists then
   begin
      // Try to drop table as temptable or as table
      Result := 'IF OBJECT_ID(''Tempdb..' + stable + ''', ''U'') IS NOT NULL OR IF OBJECT_ID(''' + stable + ''', ''U'') IS NOT NULL' + #13#10 +
         'DROP TABLE ' + stable;
   end;
   Result := 'CREATE TABLE ' + stable + ' ('#13#10;
   i := 1;

   for f in aTableModel do
   begin
      Result := Result + '  ' + f.FieldName;
      case f.FieldType of
         ftFieldID:
            begin
               if Withprimarykey then
                  Result := Result + ' int IDENTITY(1,1)'
               else
                  Result := Result + ' int';
            end;
         ftFieldString:
            begin
               if (f.MaxValue > 127) then
                  StringSize := 127
               else
                  StringSize := Round(f.MaxValue);
               if StringSize <= 0 then
                  StringSize := 127;

               Result := Result + Format(' nvarchar(%d)', [StringSize]);
            end;
         ftFieldBoolean:
            Result := Result + ' bit';
         ftFieldDouble:
            Result := Result + ' float';
         ftFieldCurrency:
            Result := Result + ' smallmoney';
         ftFieldInteger:
            Result := Result + ' int';
         ftFieldDateTime:
            Result := Result + ' datetime';
      else
         Assert(False, 'unhandled field type');
      end;

      // bij laatste geen komma
      if i < aTableModel.Count then
         komma := ','
      else
         komma := '';

      if f.IsRequired then
         Result := Result + ' NOT NULL' + komma + #13#10
      else
         Result := Result + ' NULL' + komma + #13#10;

      inc(i);
   end;

   for f in aTableModel do
   begin
      if f.FieldType = ftFieldID then
      begin
         if Withprimarykey then
            Result := Result + Format(' , CONSTRAINT PK_%s PRIMARY KEY (%s)', [f.TableName, f.FieldName]);
         Break;
      end;
   end;

   Result := Result + ');'#13#10;

   // ALTER TABLE ACTIONS2 ADD CONSTRAINT references_a
   // FOREIGN KEY (ID) REFERENCES ACTIONS(ID)
   for f in aTableModel do
   begin
      if (TBaseField_Ext(f).MetaField <> nil) and (TBaseField_Ext(f).MetaField.KeyMetaData is TFKMetaField) then
      begin
         fk := (TBaseField_Ext(f).MetaField.KeyMetaData as TFKMetaField);

         Result := Result + #13#10 + Format('ALTER TABLE %s'#13#10 + 'ADD CONSTRAINT fk_%s_%s'#13#10 + 'FOREIGN KEY (%s) REFERENCES %s(%s);'#13#10,
               [f.TableName, f.TableName, f.FieldName, f.FieldName, fk.FKTable, fk.FKField]);
      end;
   end;
end;

class function TSQLBuilder.GenerateDelete(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray;
   const dbConType: TDBConnectionType): string;
var
   stable, swhere, sjoin, sAlias: string;
  Database: string;
begin
   Database := GetDatabaseName(aQuery.MainTableField);
   stable := GetDatabasePrefix(aQuery.MainTableField, aDefaultDB, dbConType) + aQuery.Table;
   sjoin := '';

   case dbConType of
      dbtSQLServerCE:
      begin
         Result := 'Delete From ' + stable;
      end;
      dbtSQLServer, dbtREST, dbtSQLLite:
      begin
            sAlias := aQuery.GetAliasForField(aQuery.MainTableField);
            sjoin := GetJoinPart(aDefaultDB, aQuery, aParams, dbConType);
            Result := 'Delete '+ sAlias + #13#10+
                      'From '+ stable + ' ' + sAlias+#13#10+
                      sjoin;
      end
   else
      Assert(False)
   end;

   swhere := GetWherePart(aDefaultDB, aQuery, aParams, dbConType, (dbConType <> dbtSQLServerCE)); // geen alias voor CE
   if (swhere <> '') then
      Result := Result + #13#10 + 'Where ' + swhere;
end;

class function TSQLBuilder.GenerateInsert(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray;
   const dbConType: TDBConnectionType): string;

   procedure NextField(const aField, aValue: string; var afieldpart, avaluespart, avalues, afields: string);
   begin
      AddToCSVList(aField, afields);
      afieldpart := afieldpart + ', ' + aField;
      if (Length(afieldpart) > 100) then
      begin
         afields := afields + #13#10#9;
         afieldpart := '';
      end;

      AddToCSVList(aValue, avalues);
      avaluespart := avaluespart + ', ' + aValue;
      if (Length(avaluespart) > 100) then
      begin
         avalues := avalues + #13#10#9;
         avaluespart := '';
      end;
   end;

var
   f: TBaseField;
   sprevalidcheck, stable, sfields, svalues, sjoin, swhere, sgroupby, sHavingBy: string;
   svalue, sfieldpart, svaluespart: string;
   v: Variant;
begin
   Result := '';
   sfieldpart := '';
   svaluespart := '';
   stable := GetDatabasePrefix(aQuery.MainTableField, aDefaultDB, dbConType) + aQuery.Table;
   if aQuery.ActivateIdentityInsert then
      Result := 'SET IDENTITY_INSERT ' + stable + ' ON;'#13#10;

   // fields
   for f in aQuery.InsertFieldValues.Keys do
   begin
      v := aQuery.InsertFieldValues.Items[f];
      if VarIsNull(v) then
         svalue :=  'null'
      else
      begin
         svalue := '?';
         SetLength(aParams, Length(aParams) + 1);
         aParams[High(aParams)] := v;
      end;
      NextField(f.FieldName, svalue, sfieldpart, svaluespart, svalues, sfields);
      sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);
   end;

   for f in aQuery.InsertFieldFields.Keys do
      NextField(f.FieldName, GetFieldSQLWithAlias(aQuery, aQuery.InsertFieldFields.Items[f], dbConType, aParams), sfieldpart, svaluespart, svalues, sfields);
   // geen prevalidcheck, gegevens komen direct uit DB
   // sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);

   if Assigned(aQuery.InsertFromRecord) then
   begin
      sjoin := GetJoinPart(aDefaultDB, aQuery, aParams, dbConType);
      swhere := GetWherePart(aDefaultDB, aQuery, aParams, dbConType);
      if (swhere <> '') then
         swhere := 'Where ' + swhere;

      sgroupby := GetGroupByPart(aQuery, aParams, dbConType);
      if sgroupby <> '' then
         sgroupby := 'Group by ' + sgroupby;

      sHavingBy := GetHavingByPart(aDefaultDB, aQuery, aParams, dbConType);
      if sHavingBy <> '' then
         sHavingBy := 'Having ' + sHavingBy;

      Result := Result + 'Insert Into ' + stable + ' (' + sfields + ') '#13#10 + 'Select ' + svalues + #13#10 + 'From ' +
         GetTableNameAndAlias(aQuery, aQuery.InsertFromRecord.GetFieldForID, aDefaultDB, dbConType) + #13#10 + sjoin + #13#10 +
//         aQuery.InsertFromRecord.GetFieldForID.TableName + ' ' + aQuery.GetAliasForField(aQuery.InsertFromRecord.GetFieldForID) + #13#10 + sjoin + #13#10 +
         swhere + #13#10 + sgroupby + #13#10 + sHavingBy;
   end
   else
   begin
      Result := Result + 'Insert Into ' + stable + ' '#13#10 + '(' + sfields + ') '#13#10 + 'VALUES '#13#10 + '(' + svalues + '); '#13#10;
   end;

   if aQuery.RetrieveIdentityAfterInsert then
      Result := Result + 'select SCOPE_IDENTITY();'#13#10;

   if aQuery.ActivateIdentityInsert then
      Result := Result + 'SET IDENTITY_INSERT ' + stable + ' OFF';

   if sprevalidcheck <> '' then
      Result := sprevalidcheck + Result;
end;

class function TSQLBuilder.GenerateSelect(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType; const aMaxRecords: Integer = -1; const IsCTE: Boolean = False): string;
const
   NewLineStr = #13#10 + '      ';
var
   sql, stable, sfield, sfields, sfieldpart, sjoin, swhere, sOrderBy, sgroupby, sHavingBy: string;
   subquery: IQueryDetails;
   sfieldAlias: string;
   fields: TSelectFields;
   f: TBaseField;
   autojoin: TJoinableDataRecord;
   join: ISelectNext;
   Top: Integer;
begin
{ sql opbouwen in volgorde zoals deze wordt uitgevoerd }
   // search for auto join fields
   // todo: move the general query builder?
   for f in aQuery.SelectFields_Ordered do
   begin
      if f.TableName = '' then
         Continue;
      if (f.DataRecord is TJoinableDataRecord) then
      begin
         autojoin := f.DataRecord as TJoinableDataRecord;
         while autojoin <> nil do
         begin
            if autojoin.ExternalJoinField <> nil then // has joinlink?
            begin
               // (manual) join already exists?
               if not aQuery.JoinParts.JoinFieldExist(autojoin.OwnJoinField) then
               begin
                  if aQuery.QueryInterface(ISelectNext, join) = S_OK then
                  begin
                     if autojoin.OwnJoinField.IsRequired then // als niet nullable dan inner join
                        join.InnerJoin.OnFields(autojoin.OwnJoinField, autojoin.ExternalJoinField)
                     else
                        join.LeftOuterJoin.OnFields(autojoin.OwnJoinField, autojoin.ExternalJoinField);
                  end;
               end;
               // recursive search
               if (autojoin.ExternalJoinField.DataRecord is TJoinableDataRecord) then
                  autojoin := (autojoin.ExternalJoinField.DataRecord as TJoinableDataRecord)
               else
                  Break;
            end
            else
               Break;
         end;
      end;
   end;

   // fields
   fields := aQuery.SelectFields;
   for f in aQuery.SelectFields_Ordered do // must be the same order as in select!! dictionary has random hashbased order...
   begin
      if (f.TableName = '') and (not(f is TCustomSQLField)) then
         Continue;

      sfield := GetFieldSQLWithAlias(aQuery, f, dbConType, aParams);

      sfieldAlias := Fld(f.DisplayLabel);

      case fields.Items[f] of
         soSelect:
            begin
               // velden uit subquery geen 'as' geven
               if ((f.FieldName <> f.DisplayLabel) or (f is TCustomSQLField)) and (not SameText(GetStringPart(sfield, 1, '.'), sfieldAlias)) then
                  sfield := Format('%s as %s', [sfield, sfieldAlias]);
            end;
         soSum:
            sfield := Format('SUM(%s) as %s', [sfield, sfieldAlias]);
         soMin:
            sfield := Format('MIN(%s) as %s', [sfield, sfieldAlias]);
         soMax:
            sfield := Format('MAX(%s) as %s', [sfield, sfieldAlias]);
         soAvg:
            sfield := Format('AVG(%s) as %s', [sfield, sfieldAlias]);
         soCount:
            sfield := Format('COUNT(%s) as %s', [sfield, sfieldAlias]);
         soCountDistinct:
            sfield := Format('COUNT(distinct %s) as %s', [sfield, sfieldAlias]);
      else
         Assert(False, 'unsupported type');
      end;

      AddToCSVList(sfield, sfields);

      sfieldpart := sfieldpart + ', ' + sfield;
      if (Length(sfieldpart) > 100) then
      begin
         sfields := sfields + NewLineStr;
         sfieldpart := '';
      end;
   end;

   // laatste nieuwe regel eraf halen als er niets op volgende regel is
   if SameText(RightStr(sfields, Length(NewLineStr)), NewLineStr) then
      sfields := Copy(sfields, 1, Length(sfields) - Length(NewLineStr));

   // single field from subquerie
   if (aQuery.SelectFieldsSubqueries <> nil) then
   begin
      for subquery in aQuery.SelectFieldsSubqueries do
      begin
         Assert(subquery.SelectFields_Ordered.Count = 1, 'subquery mag maar 1 veld bevatten');
         subquery.SetParentQuery(aQuery);
         sfield := #13#10'(' + IndentSQL(GenerateSelect(aDefaultDB, subquery, aParams, dbConType)) + ') as ' + subquery.SelectFields_Ordered.First.FieldName;
         aQuery.SelectFields.Add(subquery.SelectFields_Ordered.First, soSelect);
         aQuery.SelectFields_Ordered.Add(subquery.SelectFields_Ordered.First);
         subquery.SetParentQuery(nil); // reset, otherwise mem leak due to circular pointers!

         AddToCSVList(sfield, sfields);
      end;
   end;

   if aQuery.FromSubQuery = nil then
   begin
      if IsCTE then
         stable := aQuery.MainTableField.TableName
      else
         stable := aQuery.Table;
      stable := GetDatabasePrefix(aQuery.MainTableField, aDefaultDB, dbConType) + stable;
      // if (aQuery.AliasCount > 1) or (aQuery.JoinParts.Count > 0) then    altijd korte alias gebruiken
      stable := stable + ' ' + aQuery.GetAliasForField(aQuery.MainTableField);
   end
   else
   begin
      aQuery.FromSubQuery.SetParentQuery(aQuery);
      stable := '(' + IndentSQL(GenerateSelect(aDefaultDB, aQuery.FromSubQuery, aParams, dbConType)) + ') ' +
         aQuery.GetAliasForField(aQuery.FromSubQuery.SelectFields_Ordered.First);
      aQuery.FromSubQuery.SetParentQuery(nil); // reset, otherwise mem leak due to circular pointers!
   end;

   sjoin := GetJoinPart(aDefaultDB, aQuery, aParams, dbConType);

   swhere := GetWherePart(aDefaultDB, aQuery, aParams, dbConType);
   if swhere <> '' then
      swhere := 'Where ' + swhere;

   sgroupby := GetGroupByPart(aQuery, aParams, dbConType);
   if sgroupby <> '' then
      sgroupby := 'Group by ' + sgroupby;

   sHavingBy := GetHavingByPart(aDefaultDB, aQuery, aParams);
   if sHavingBy <> '' then
      sHavingBy := 'Having ' + sHavingBy;

   sOrderBy := GetOrderByPart(aQuery, aParams, dbConType);
   if sOrderBy <> '' then
      sOrderBy := 'Order by ' + sOrderBy;

   // make complete sql
   sql := 'Select ';
   if aQuery.DoDistinct then
      sql := sql + 'DISTINCT ';
    if (aMaxRecords > 0) or (aQuery.DoTopCount >= 0) then
    begin
      // take minimum if both are filled
      Top := MaxInt;
      if (aQuery.DoTopCount >= 0) then
         Top := Min(aQuery.DoTopCount, Top);
      if (aMaxRecords > 0) then
         Top := Min(aMaxRecords, Top);
      sql := sql + Format('TOP %d ', [Top]);
    end;

   sql := sql + sfields + #13#10 + 'From ' + stable + #13#10 + GetTableHints(aQuery.TableHints) + #13#10 + sjoin + #13#10 +
   // aQuery.TempJoin +
      swhere + #13#10 + sgroupby + #13#10 + sHavingBy + #13#10 + sOrderBy;

   Result := sql;

end;

class function TSQLBuilder.GenerateSQL(const aDefaultDB: string; const aQuery: IQueryDetails; out aParams: TVariantArray; aMaxRecords: Integer = -1;
   dbConType: TDBConnectionType = dbtSQLServer): string;
var CTE: IQueryBuilder;
    cteString: string;
begin
   aParams := nil;
   cteString := '';
   for CTE in aQuery.CTEs do
   begin
      if (cteString = '') then
         cteString := ';with '
      else
         cteString := cteString +', ';
      cteString := cteString+CTE.Details.CTEName+' as ('+#13#10+GenerateSelect(aDefaultDB, CTE.Details, aParams, dbConType, aMaxRecords, True)+')'+#13#10;
   end;

   case aQuery.QueryType of
      qtSelect:
         Result := GenerateSelect(aDefaultDB, aQuery, aParams, dbConType, aMaxRecords);
      qtUpdate:
         Result := GenerateUpdate(aDefaultDB, aQuery, aParams, dbConType);
      qtInsert:
         Result := GenerateInsert(aDefaultDB, aQuery, aParams, dbConType);
      qtDelete:
         Result := GenerateDelete(aDefaultDB, aQuery, aParams, dbConType);
   else
      Assert(False);
   end;

   Result := RemoveExtraEnters(cteString+Result);
end;

class function TSQLBuilder.GenerateUpdate(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType): string;
var
   f: TBaseField;
   sprevalidcheck, stable, sfields, swhere, sjoin: string;
   v: Variant;
begin
   stable := GetDatabasePrefix(aQuery.MainTableField, aDefaultDB, dbConType) + aQuery.Table;

   // fields (normal update fields)
   if aQuery.UpdateFieldValues <> nil then
      for f in aQuery.UpdateFieldValues.Keys do
      begin
         AddToCSVList(f.FieldName + ' = ', sfields);

         v := aQuery.UpdateFieldValues.Items[f];
         if VarIsNull(v) then
            sfields := sfields + 'null'
         else
         begin
            sfields := sfields + '?';
            SetLength(aParams, Length(aParams) + 1);
            aParams[High(aParams)] := v;
         end;

         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);
      end;

   // fields (transaction save increment of field values (no gap between fetch and client side increment but all server(db) side)
   if aQuery.UpdateIncFieldValues <> nil then
      for f in aQuery.UpdateIncFieldValues.Keys do
      begin
         v := aQuery.UpdateIncFieldValues.Items[f];
         if not VarIsNull(v) then
         begin
            AddToCSVList(f.FieldName + ' = ' + f.FieldName + ' + ?', sfields); // field1 = field1 + 1

            SetLength(aParams, Length(aParams) + 1);
            aParams[High(aParams)] := aQuery.UpdateIncFieldValues.Items[f];
         end;

         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);
      end;

   // fields (normal update fields with field)
   if aQuery.UpdateFieldFields <> nil then
      for f in aQuery.UpdateFieldFields.Keys do
      begin
         AddToCSVList(f.FieldName + ' = ' + GetFieldSQLWithAlias(aQuery, aQuery.UpdateFieldFields.Items[f], dbConType, aParams), sfields);

         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);
      end;

   if aQuery.UpdateIncFieldFields <> nil then
      for f in aQuery.UpdateIncFieldFields.Keys do
      begin
         AddToCSVList(f.FieldName + ' = ' + f.FieldName + ' + ' + GetFieldSQLWithAlias(aQuery, aQuery.UpdateFieldFields.Items[f], dbConType, aParams), sfields);
         // field1 = field1 + field2

         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f);
      end;

   sjoin := GetJoinPart(aDefaultDB, aQuery, aParams, dbConType);

   case dbConType of
      dbtSQLServerCE:
         begin
            Assert(sjoin = '', 'CE kan geen joins aan in update querys');
            Result := 'Update ' + stable + ' '#13#10 + 'Set ' + sfields + ' '#13#10;

         end;
      dbtSQLServer, dbtREST, dbtSQLLite:
         begin
            stable := stable + ' ' + aQuery.GetAliasForField(aQuery.MainTableField);
            Result := 'Update ' + aQuery.GetAliasForField(aQuery.MainTableField) + ' '#13#10 + 'Set ' + sfields + ' '#13#10 + 'From ' + stable +
               ' '#13#10 + sjoin;
         end;
   else
      Assert(False, 'Uknown db connection type for update command');
   end;

   swhere := GetWherePart(aDefaultDB, aQuery, aParams, dbConType, (dbConType <> dbtSQLServerCE)); // Geen alias voor CE
   if swhere <> '' then
      Result := Result + #13#10 + 'Where ' + swhere;

   if sprevalidcheck <> '' then
      Result := sprevalidcheck + Result;
end;

class function TSQLBuilder.GenerateValidationSQL(const aQuery: IQueryDetails): string;
var
   sprevalidcheck: string;
   f: TBaseField;
begin
   // fields (normal update fields)
   if aQuery.UpdateFieldValues <> nil then
      for f in aQuery.UpdateFieldValues.Keys do
      begin
         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f, False { all errors } );
      end;

   // fields (transaction save increment of field values (no gap between fetch and client side increment but all server(db) side)
   if aQuery.UpdateIncFieldValues <> nil then
      for f in aQuery.UpdateIncFieldValues.Keys do
      begin
         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f, False { all errors } );
      end;

   if aQuery.InsertFieldValues <> nil then
      for f in aQuery.InsertFieldValues.Keys do
      begin
         sprevalidcheck := sprevalidcheck + GetPreValidationCheck(aQuery, f, False { all errors } );
      end;

   Result := sprevalidcheck;
end;

class function TSQLBuilder.GetJoinPart(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType): string;
var
   joins: TJoinPartList;
   jp: TJoinPart;
   sjoin: string;
   i: Integer;
   bnewjoin: Boolean;
   issubquery: Boolean;
begin
   sjoin := '';
   bnewjoin := False;
   issubquery := False;
   // join statement
   joins := aQuery.JoinParts;
   for jp in joins do
   begin
      if jp.FOperation in [joInnerJoin, joLeftJoin, joRightJoin] then
         bnewjoin := True;

      case jp.FOperation of
         joInnerJoin:
            sjoin := sjoin + IfThen(sjoin <> '', ')') + #13#10 + '     inner join ';
         joLeftJoin:
            sjoin := sjoin + IfThen(sjoin <> '', ')') + #13#10 + '     left join ';
         joRightJoin:
            sjoin := sjoin + IfThen(sjoin <> '', ')') + #13#10 + '     right join ';
         joAnd:
            sjoin := sjoin + ' And ';
         joOr:
            sjoin := sjoin + ' Or ';
         joOpenBracket:
            sjoin := sjoin + '(';
         joCloseBracket:
            sjoin := sjoin + ')';
         joField:
            begin
               if jp is TJoinPartField then
               begin
                  with jp as TJoinPartField do
                     if bnewjoin then
                     begin
                        if issubquery then
                           sjoin := sjoin + GetTableHints(FTableHints) + ' on ('
                        else
                           sjoin := sjoin + GetTableNameAndAlias(aQuery, FJoinField, aDefaultDB, dbConType) + GetTableHints(FTableHints) + ' on (';
                        bnewjoin := False;
                        issubquery := False; // reset temp flag
                     end;
               end;

               if jp is TJoinPartFieldValue then
               begin
                  with jp as TJoinPartFieldValue do
                  begin
                     // field
                     sjoin := sjoin + GetFieldSQLWithAlias(aQuery, FJoinField, dbConType, aParams);
                     // operator
                     case FCompare of
                        jcEqual:
                           sjoin := sjoin + ' = ';
                        jcNotEqual:
                           sjoin := sjoin + ' <> ';
                        jcIs:
                           sjoin := sjoin + ' is ';
                        jcIsNot:
                           sjoin := sjoin + ' is not ';
                        jcGreater:
                           sjoin := sjoin + ' > ';
                        jcGreaterEqual:
                           sjoin := sjoin + ' >= ';
                        jcLess:
                           sjoin := sjoin + ' < ';
                        jcLessEqual:
                           sjoin := sjoin + ' <= ';
                        jcLike:
                           sjoin := sjoin + ' like ''';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     // param
                     case FCompare of
                        jcEqual, jcNotEqual, jcGreater, jcGreaterEqual, jcLess, jcLessEqual, jcIs, jcIsNot:
                           begin
                              if (FCompare in [jcIs, jcIsNot]) and (VarIsNull((jp as TJoinPartFieldValue).JoinValue)) then
                                 sjoin := sjoin + 'null '
                              else
                              begin
                                 sjoin := sjoin + '? ';
                                 SetLength(aParams, Length(aParams) + 1);
                                 aParams[High(aParams)] := (jp as TJoinPartFieldValue).JoinValue;
                              end;
                           end;
                        jcLike:
                           sjoin := sjoin + string((jp as TJoinPartFieldValue).JoinValue) + ''' ';
                     else
                        Assert(False, 'unsupported type');
                     end;
                  end;
               end
               else if jp is TJoinPartFieldSet then
               begin
                  with (jp as TJoinPartFieldSet) do
                  begin
                     // field
                     sjoin := sjoin + GetFieldSQLWithAlias(aQuery, FJoinField, dbConType, aParams);
                     // operator
                     case FCompare of
                        jcInSet:
                           sjoin := sjoin + ' in (';
                        jcNotInSet:
                           sjoin := sjoin + ' not in (';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     for i := 0 to High(FJoinSet) do
                     begin
                        if i = 0 then
                           sjoin := sjoin + '? '
                        else
                           sjoin := sjoin + ',? ';
                        SetLength(aParams, Length(aParams) + 1);
                        aParams[High(aParams)] := FJoinSet[i];
                     end;
                     sjoin := sjoin + ') ';
                  end;
               end
               else if jp is TJoinPartFieldField then
               begin
                  with (jp as TJoinPartFieldField) do
                  begin
                     // field
                     sjoin := sjoin + GetFieldSQLWithAlias(aQuery, FJoinField, dbConType, aParams);
                     // operator
                     case FCompare of
                        jcEqualField:
                           sjoin := sjoin + ' = ';
                        jcNotEqualField:
                           sjoin := sjoin + ' <> ';
                        jcGreaterField:
                           sjoin := sjoin + ' > ';
                        jcGreaterEqualField:
                           sjoin := sjoin + ' >= ';
                        jcLessField:
                           sjoin := sjoin + ' < ';
                        jcLessEqualField:
                           sjoin := sjoin + ' <= ';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     sjoin := sjoin + GetFieldSQLWithAlias(aQuery, FSourceField, dbConType, aParams);
                  end;
               end
               else
                  Assert(False, 'unsupported class: ' + jp.classname);
            end;
         joSubQuery:
            begin
               if jp is TJoinPartSubQuery then
               begin
                  with jp as TJoinPartSubQuery do
                  begin
                     FSubQuery.SetParentQuery(aQuery);

                     sjoin := sjoin + '(' + IndentSQL(GenerateSelect(aDefaultDB, FSubQuery, aParams, dbConType)) + ') ' +
                        aQuery.GetAliasForField(FSubQuery.SelectFields_Ordered.First);
                     issubquery := True; // set temp flag for next "on" join fields processing

                     FSubQuery.SetParentQuery(nil); // reset, otherwise mem leak due to circular pointers!
                  end;
               end
               else
                  Assert(False, 'unsupported class: ' + jp.classname);
            end
      else
         Assert(False, 'unsupported type');
      end;
   end;

   Result := Copy(sjoin, 3, Length(sjoin)); // 1e #13#10 erafhalen
   if (Trim(Result) <> '') then
      Result := Result+')';
end;

class function TSQLBuilder.GetOrderByPart(const aQuery: IQueryDetails; var aParams: TVariantArray;const dbConType: TDBConnectionType): string;
var
   OrderBys: TOrderByPartList;
    o: TOrderByPart;
    sOrderBy: string;
begin
   sOrderBy := '';
   OrderBys := aQuery.OrderByParts;
   for o in OrderBys do
   begin
      with o do
      begin
         AddToCSVList(GetFieldSQLWithAlias(aQuery, FOrderByField, dbConType, aParams), sOrderBy);

         case FOperation of
            obAsc:
               sOrderBy := sOrderBy + ' asc ';
            obDesc:
               sOrderBy := sOrderBy + ' desc ';
         else
            Assert(False, 'unsupported type');
         end;
      end;
   end;
   Result := sOrderBy;
end;

class function TSQLBuilder.GetPreValidationCheck(const aQuery: IQueryDetails; aField: TBaseField; aStopOnError: Boolean): string;
var
   constraint: TFieldConstraintMeta;
   FKField, FKField2: TBaseTableAttribute;
   f2: TBaseField;
   sfield, s, svalues: string;
begin
   Result := '';

   // select 1 where 'test' in ('test', 'test2')
   // select 1 from Table where id = :id and (field2 in ('test', 'test2'))
   if (TBaseField_Ext(aField).MetaField <> nil) and (TBaseField_Ext(aField).MetaField.ConstraintMeta <> nil) then
   begin
      constraint := TBaseField_Ext(aField).MetaField.ConstraintMeta;
      sfield := constraint.TableField.FieldMetaData.FieldName;

      svalues := '';
      for s in constraint.ValueConstraints do
      begin
         if svalues = '' then
            svalues := QuotedStr(s)
         else
            svalues := svalues + ', ' + QuotedStr(s);
      end;

      // same table?
      f2 := nil;
      if constraint.IsSameTableField(TBaseField_Ext(aField).MetaField) then
      begin
         if aQuery.UpdateFieldValues <> nil then
            f2 := aQuery.UpdateFieldValues.GetFieldByName(sfield);
         if f2 = nil then
            if aQuery.UpdateIncFieldValues <> nil then
               f2 := aQuery.UpdateIncFieldValues.GetFieldByName(sfield);
         if f2 = nil then
            if aQuery.InsertFieldValues <> nil then
               f2 := aQuery.InsertFieldValues.GetFieldByName(sfield);
         if f2 = nil then
            if aQuery.SelectFields_Ordered <> nil then
               f2 := aQuery.SelectFields_Ordered.GetFieldByName(sfield);
         if f2 = nil then
               f2 := aQuery.MainTableField.DataRecord.FieldByName(sfield);

         if f2 <> nil then
         begin
           if f2.IsEmpty then
           begin
             if aQuery.MainTableField.IsEmptyOrNull then
                  Result := 'select 1 from' + GetDatabaseName(aQuery.MainTableField) + '..' + aQuery.Table +
                         ' where (' + f2.FieldName + ' in (' + svalues + '))'
             else
                  Result := 'select 1 from ' + GetDatabaseName(aQuery.MainTableField) + '..' + aQuery.Table + ' where ' + aQuery.MainTableField.FieldName +
                     ' = ' + aQuery.MainTableField.ValueAsString + ' and (' + f2.FieldName + ' in (' + svalues + '))'
           end
            else
               Result := 'select 1 where ' + QuotedStr(f2.ValueAsString) + ' in (' + svalues + ')';
         end;
      end
      else
      begin
         if aField.IsEmptyOrNull then
            Exit;

         //double join?
         if constraint.FKField <> nil then
         begin
           FKField  := constraint.FKField;
           FKField2 := constraint.TableField;

           Result := 'select 1 from ' +
                     GetDatabaseName(fkfield.TableMetaData.DBName) + '..' +
                     fkfield.TableMetaData.Table + ' fk1 ' +
                     'inner join ' + GetDatabaseName(fkfield2.TableMetaData.DBName) + '..' +
                     fkfield2.TableMetaData.Table + ' fk2 ' +
                     'on fk2.ID = fk1.' + fkfield.FieldMetaData.FieldName + ' ' +
                     'where fk1.ID = ' + aField.ValueAsString + ' ' +
                     'and (fk2.' + fkfield2.FieldMetaData.FieldName + ' in (' + svalues + '))';
         end
         else
         begin
            FKField := constraint.TableField;

            Result := 'select 1 from ' +
                   GetDatabaseName(fkfield.TableMetaData.DBName) +
                   '..' + fkfield.TableMetaData.Table +
                   ' where ID = ' + aField.ValueAsString +
                   ' and (' + fkfield.FieldMetaData.FieldName + ' in (' + svalues + '))';
         end;
      end;
   end;

   // IF NOT EXISTS(Select 1 where 1=2)
   // begin
   // RAISERROR ('You made a HUGE mistake',18,1);
   // return;
   // end;
   if Result <> '' then
   begin
      sfield := aField.TableName + '.' + aField.FieldName;
      Result := 'IF NOT EXISTS( ' + Result + ' ) BEGIN '#13#10;
      if aStopOnError then
         Result := Result + Format('  RAISERROR (''Constraint check failed on field "%s"!'',18,1);'#13, [sfield]) + '  return;'#13
      else
         Result := Result + Format('  select ''%s'', ''Constraint check failed on field "%s"!'';'#13, [sfield, sfield]);
      Result := Result + 'END;'#13#10;
   end;
end;

class function TSQLBuilder.GetTableHints(aTableHints: TTableHints): string;
var
   h: TTableHint;
   s: string;
begin
   Result := '';
   s := '';
   for h in aTableHints do
   begin
      if s = '' then
         s := TypInfo.GetEnumName(TypeInfo(TTableHint), Ord(h))
      else
         s := s + ', ' + TypInfo.GetEnumName(TypeInfo(TTableHint), Ord(h));
   end;
   if s <> '' then
      Result := Format(' with (%s) ', [s]);
end;

class function TSQLBuilder.GetDatabaseName(const aField: TBaseField): string;
begin
   Result := GetDatabaseName(aField.DatabaseTypeName);
end;

class function TSQLBuilder.GetDatabaseName(const aDBNameType: string): string;
var
   dbcon: DB.Settings.TDBConfig;
begin
   Result := '';
   dbcon := DB.Settings.TDBSettings.Instance.GetDBConnection(aDBNameType, TBaseDataCRUD.GetDefaultDBTypeOfDBName(aDBNameType));
   Assert(dbcon <> nil);
   Result := Fld(dbcon.Settings.DatabaseName);
end;

class function TSQLBuilder.GetDatabasePrefix(const aField: TBaseField; const aDefaultDatabase: string; dbConType: TDBConnectionType): string;
var
   Database: string;
begin
   Result := '';
   Database := GetDatabaseName(aField);
   if (Database <> '') and (Database <> Fld(aDefaultDatabase)) and (dbConType <> dbtSQLServerCE) then
      Result := Database + '..';
end;

class function TSQLBuilder.GetTableNameAndAlias(const aQuery: IQueryDetails; const aField: TBaseField; const aDefaultDatabase: string; dbConType: TDBConnectionType): string;
var CTE: IQueryBuilder;
    Table, Alias: string;
begin
   Table := aField.TableName;
   Alias := aQuery.GetAliasForField(aField);
   for CTE in aQuery.CTEs do
   begin
      if CTE.Details.SelectFields_Ordered.Contains(aField) then
      begin
         Table := CTE.Details.CTEName;
         Alias := CTE.Details.GetAliasForField(CTE.Details.MainTableField);
         Break;
      end;
   end;

   Result := GetDatabasePrefix(aField, aDefaultDatabase, dbConType) + Table + ' ' + Alias;
end;

class function TSQLBuilder.GetFieldSQLWithAlias(const aQuery: IQueryDetails; const aField: TBaseField; const dbConType: TDBConnectionType; var aParams: TVariantArray; const WithAlias: Boolean = True): string;
var
   CustomAlias: string;

   function IsFromSubQuery: Boolean;

      function IsFromSubQuery(const Qry: IQueryDetails): Boolean;
      begin
         Result := Assigned(Qry) and Qry.SelectFields.ContainsKey(aField);
         if Result then
            CustomAlias := aQuery.GetAliasForField(Qry.SelectFields_Ordered.First) + '.';
      end;

   var jp: TJoinPart;
   begin
      Result := IsFromSubQuery(aQuery.FromSubQuery);
      if Result then
         Exit;
      for jp in aQuery.JoinParts do
      begin
         if (jp.FOperation = joSubQuery) and (jp is TJoinPartSubQuery) then
         begin
            Result := IsFromSubQuery((jp as TJoinPartSubQuery).FSubQuery);
            if Result then
               Exit
         end;
      end;
   end;

   function IsFromCTE: Boolean;
   var CTE: IQueryBuilder;
   begin
      Result := False;
      for CTE in aQuery.CTEs do
            begin
         if CTE.Details.SelectFields_Ordered.Contains(aField) then
               begin
            CustomAlias := CTE.Details.GetAliasForField(CTE.Details.MainTableField) + '.';
                  Exit(True);
               end;
            end;
         end;
begin
   // if ((aQuery.AliasCount > 1) or (aQuery.JoinParts.Count > 0)) and WithAlias then
   CustomAlias := '';
   if IsFromSubQuery then
      Result := CustomAlias + Fld(aField.DisplayLabel)
   else if IsFromCTE then
      Result := CustomAlias + Fld(aField.DisplayLabel)
   else if (aField is TCustomSQLField) then
      Result := (aField as TCustomSQLField).GetCustomSQL(aQuery,dbConType, aParams,  WithAlias)
   else if WithAlias then
      Result := aQuery.GetAliasForField(aField) + '.' + aField.FieldName
   else
      Result :=  aField.FieldName;
end;

class function TSQLBuilder.GetGroupByPart(const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType): string;
var
   GroupBys: TGroupByPart;
    b: TBaseField;
   sgroupby: string;
begin
   sgroupby := '';
   GroupBys := aQuery.GroupByPart;
   if Assigned(GroupBys) then
   begin
      for b in GroupBys.FGroupBySet do
      begin
         if sgroupby <> '' then
            sgroupby := sgroupby + ', ';

         sgroupby := sgroupby + GetFieldSQLWithAlias(aQuery, b, dbConType, aParams);
      end;
   end;
   Result := sgroupby;
end;

class function TSQLBuilder.GetHavingByPart(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string;
begin
   Result := GetWherePart(aDefaultDB, aQuery, aParams, aQuery.HavingParts, dbConType, AliasFields);
end;

class function TSQLBuilder.GetWherePart(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string;
begin
   Result := GetWherePart(aDefaultDB, aQuery, aParams, aQuery.WhereParts, dbConType, AliasFields);
end;

class function TSQLBuilder.GetWherePart(const aDefaultDB: string; const aQuery: IQueryDetails; var aParams: TVariantArray; wheres: TWherePartList; const dbConType: TDBConnectionType = dbtSQLServer; const AliasFields: Boolean = True): string;
   
   function GetWhereFieldSQL(FField: TBaseField; WhereType: TSelectOperation): string;
   begin
      Result := GetFieldSQLWithAlias(aQuery, FField, dbConType, aParams, AliasFields);
      case WhereType of
         soSum:
            Result := Format('SUM(%s)', [Result]);
         soMin:
            Result := Format('MIN(%s)', [Result]);
         soMax:
            Result := Format('MAX(%s)', [Result]);
         soAvg:
            Result := Format('AVG(%s)', [Result]);
         soCount:
            Result := Format('COUNT(%s)', [Result]);
         soCountDistinct:
            Result := Format('COUNT(distinct %s)', [Result]);
      end;
   end;

   procedure AddCollate(var aWhere: string; const aCollateType: TCollateType);
   var CollateStr: string;
   begin
      CollateStr := '';
      case aCollateType  of
         ctGeen: ;
         ctDataBaseDefault:               CollateStr := 'Database_Default';
         ctLatin1_General_CI_AI:          CollateStr := 'Latin1_General_CI_AI'; // André = Andre
         ctSQL_Latin1_General_CP1_CS_AS:  CollateStr := 'SQL_Latin1_General_CP1_CS_AS'; // Case sensitive
      else
         Assert(False)
      end;
      if (CollateStr <> '') then
         aWhere := aWhere + ' Collate ' + CollateStr;
   end;

var
   w: TWherePart;
   swhere: string;
   i: Integer;
begin
   swhere := '';
   // where statement
   for w in wheres do
   begin
      case w.FOperation of
         woAnd:
            begin
               if (swhere <> '') then // do not start with and (in case of where object parameter, it starts with dummy and/or)
                  swhere := swhere + #13#10 + 'And ';
            end;
         woOr:
            begin
               if (swhere <> '') then
                  swhere := swhere + #13#10 + 'Or ';
            end;
         woOpenBracket:
            swhere := swhere + ' (';
         woCloseBracket:
            swhere := swhere + ') ';
         woField:
            begin
               if w is TWherePartFieldValue then
               begin
                  with w as TWherePartFieldValue do
                     if (FCompare = wcEqualOrNull) then
                  begin
                     Assert(FCompareSubQuery = nil);
                        case dbConType of
                           dbtSQLServer:
                           begin
                              swhere := swhere + 'isnull('+ GetFieldSQLWithAlias(aQuery, FField, dbConType, aParams, AliasFields) +',?) = ?';
                              AddCollate(swhere, FCollateType);
                              SetLength(aParams, Length(aParams) + 1);
                              aParams[High(aParams)] := (w as TWherePartFieldValue).CompareValue;
                           end;
                           dbtSQLServerCE, dbtSQLLite, dbtMYSQL:
                           begin
                              swhere := swhere + '(' + GetFieldSQLWithAlias(aQuery, FField, dbConType, aParams, AliasFields) + ' = ? or ' +
                                 GetFieldSQLWithAlias(aQuery, FField, dbConType, aParams, AliasFields) + ' is null) ';
                           end;
                        end;
                     SetLength(aParams, Length(aParams) + 1);
                     aParams[High(aParams)] := (w as TWherePartFieldValue).CompareValue;
                  end
                  else
                  begin
                     // field
                     swhere := swhere + GetWhereFieldSQL(FField, FFieldSelectType);
                        AddCollate(swhere, FCollateType);
                     // operator
                     case FCompare of
                        wcEqual:
                           swhere := swhere + ' = ';
                        wcNotEqual:
                           swhere := swhere + ' <> ';
                        wcIs:
                           swhere := swhere + ' is ';
                        wcIsNot:
                           swhere := swhere + ' is not ';
                        wcGreater:
                           swhere := swhere + ' > ';
                        wcGreaterEqual:
                           swhere := swhere + ' >= ';
                        wcLess:
                           swhere := swhere + ' < ';
                        wcLessEqual:
                           swhere := swhere + ' <= ';
                        wcLike:
                           swhere := swhere + ' like ''';
                        wcNotLike:
                           swhere := swhere + ' not like ''';
                        wcInQuerySet:
                           swhere := swhere + ' in';
                        wcNotInQuerySet:
                           swhere := swhere + ' not in';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     // param
                     case FCompare of
                           wcEqual, wcNotEqual, wcGreater, wcGreaterEqual, wcLess, wcLessEqual, wcIs, wcIsNot, wcInQuerySet, wcNotInQuerySet:
                           begin
                              if (FCompare in [wcIs, wcIsNot]) then
                                 Assert(FCompareSubQuery = nil, '"IS" is not supported with subqueries');
                              if (FCompare in [wcInQuerySet, wcNotInQuerySet]) then
                                 Assert(FCompareSubQuery <> nil, '"In" is only supported with subqueries');

                              if (FCompare in [wcIs, wcIsNot]) and (VarIsNull((w as TWherePartFieldValue).CompareValue)) then
                                 swhere := swhere + 'null '
                              else
                              begin
                                 if FCompareSubQuery = nil then
                                 begin
                                    swhere := swhere + '? ';
                                    SetLength(aParams, Length(aParams) + 1);
                                    aParams[High(aParams)] := (w as TWherePartFieldValue).CompareValue;
                                 end
                                 else
                                 begin
                                    Assert(FCompareSubQuery.SelectFields_Ordered.Count = 1, 'subquery mag maar 1 veld bevatten');
                                    FCompareSubQuery.SetParentQuery(aQuery);
                                    swhere := swhere + ' (' + IndentSQL(GenerateSelect(aDefaultDB, FCompareSubQuery, aParams, dbConType)) + ') ';
                                    FCompareSubQuery.SetParentQuery(nil); // reset, otherwise mem leak due to circular pointers!
                                 end;
                              end;
                           end;
                        wcLike, wcNotLike:
                           begin
                              Assert(FCompareSubQuery = nil);
                              swhere := swhere + string((w as TWherePartFieldValue).CompareValue) + ''' ';
                           end
                     else
                        Assert(False, 'unsupported type');
                     end;
                  end;
               end
               else if w is TWherePartFieldSet then
               begin
                  with (w as TWherePartFieldSet) do
                  begin
                     // field
                     swhere := swhere + GetWhereFieldSQL(FField, FFieldSelectType);
                     AddCollate(swhere, FCollateType);
                     // operator
                     case FCompare of
                        wcInSet:
                           swhere := swhere + ' in (';
                        wcNotInSet:
                           swhere := swhere + ' not in (';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     for i := 0 to High(FCompareSet) do
                     begin
                        if i = 0 then
                           swhere := swhere + '? '
                        else
                           swhere := swhere + ',? ';
                        SetLength(aParams, Length(aParams) + 1);
                        aParams[High(aParams)] := FCompareSet[i];
                     end;
                     swhere := swhere + ') ';
                  end;
               end
               else if w is TWherePartFieldField then
               begin
                  with (w as TWherePartFieldField) do
                  begin
                     // field
                     swhere := swhere + GetWhereFieldSQL(FField, FFieldSelectType);
                     AddCollate(swhere, FCollateType);
                     // operator
                     case FCompare of
                        wcEqualField:
                           swhere := swhere + ' = ';
                        wcNotEqualField:
                           swhere := swhere + ' <> ';
                        wcGreaterField:
                           swhere := swhere + ' > ';
                        wcGreaterEqualField:
                           swhere := swhere + ' >= ';
                        wcLessField:
                           swhere := swhere + ' < ';
                        wcLessEqualField:
                           swhere := swhere + ' <= ';
                     else
                        Assert(False, 'unsupported type');
                     end;

                     swhere := swhere + GetWhereFieldSQL(FCompareField, FFieldSelectType);
                  end;
               end
               else
                  Assert(False, 'unsupported class: ' + w.classname);
            end;
         woExists, woNotExists:
            begin
               with w as TWherePartSubQuery do
               begin
                  (FQuery as IQueryDetails).SetParentQuery(aQuery);
                  swhere := swhere + IfThen(w.FOperation = woNotExists,'not ') + 'Exists(' + IndentSQL(GenerateSelect(aDefaultDB, FQuery as IQueryDetails, aParams, dbConType)) + ')';
                  (FQuery as IQueryDetails).SetParentQuery(nil); // reset, otherwise mem leak due to circular pointers!
               end;
               end;
      else
         Assert(False, 'unsupported type');
      end;
   end;

   Result := swhere;
end;

class function TSQLBuilder.IndentSQL(const aSQL: string): string;
begin
   Result := StringReplace(RemoveExtraEnters(aSQL), #13#10, #13#10+'        ',[rfReplaceAll])
end;

class function TSQLBuilder.RemoveExtraEnters(const aSQL: string): string;
begin
   Result := aSQL;
   // remove double enters
   while ContainsText(Result, #13#10#13#10) do
      Result := StringReplace(Result, #13#10#13#10, #13#10, [rfReplaceAll]);
   // Enter achteraan weghalen
   if SameText(RightStr(Result, 2), #13#10) then
      Result := Copy(Result, 1, Length(Result) - 2);
end;

end.
