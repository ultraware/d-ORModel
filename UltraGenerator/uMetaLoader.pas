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
unit uMetaLoader;

interface

uses
  Data.CRUDSettings;

type
  TMetaLoader = class
  public
    class procedure FillFieldsForTable(const aTable: TCRUDTable);
  end;

implementation

uses
  SysUtils, Classes, Typinfo, Variants, StrUtils,
  Data.Win.ADODB, Db, Math,
  DB.Connection, Meta.Data, DB.ConnectionPool, Data.CustomTypes,
  DB.Connection.SQLServer, Data.CRUD, DB.Settings, Data.DataRecord;

function FieldTypeConversion(const aDelphiFieldType: DB.TFieldType): Meta.Data.TFieldType;
begin
  case aDelphiFieldType of
  //  ftUnknown: ;
    ftAutoInc:    Result := ftFieldID;

    ftString:     Result := ftFieldString;
    ftSmallint,
    ftInteger,
    ftWord:       Result := ftFieldInteger;
    ftBoolean:    Result := ftFieldBoolean;

    ftBCD,        //note: Decimal(9,3) and smallmoney have both BCD, we distinguish later
    ftCurrency:
                  Result := ftFieldCurrency;
    ftFloat,
    ftFMTBcd,
    ftExtended,
    ftSingle:     Result := ftFieldDouble;
//    ftBCD,        //note: Decimal(9,3) and smallmoney have both BCD, we distinguish later
//    ftCurrency:   Result := ftFieldCurrency;
//    ftTime,
//    ftTimeStamp:  Result := ftFieldTime;
    ftDate,
    ftDateTime:   Result := ftFieldDateTime;
    ftBlob,
    ftMemo,
    ftGraphic,
    ftFmtMemo,
    ftBytes,
    ftVarBytes,
    ftTypedBinary,
    ftWideMemo,
//    ftVarBytes:   Result := ftFieldBLOB;
//    ftParadoxOle: ;
//    ftDBaseOle: ;
//    ftCursor: ;
    ftFixedWideChar,
//    ftFixedChar:  Result := ftFieldChar;
    ftWideString: Result := ftFieldString;
//    ftLargeint:   Result := ftFieldInt64;
//    ftADT: ;
//    ftArray: ;
//    ftReference: ;
//    ftDataSet: ;
//    ftOraBlob: ;
//    ftOraClob: ;
//    ftVariant:    Result := ftFieldVariant;
//    ftInterface: ;
//    ftIDispatch: ;
//    ftGuid: ;
//    ftOraTimeStamp: ;
//    ftOraInterval: ;
//    ftShortint,
//    ftByte,
//    ftLongWord:  Result := ftFieldCardinal;
//    ftConnection: ;
//    ftParams: ;
//    ftStream: ;
//    ftTimeStampOffset: ;
//    ftObject: ;
  else
    //Result := ftFieldUnknown;
    raise Exception.Create('Unsupported type: ' + TypInfo.GetEnumName(TypeInfo(DB.TFieldType), Ord(aDelphiFieldType)) );
  end;
end;

function GetFieldSize(aField : TField): Integer;
begin
  Result := 0;
  if aField is TStringField then
    Result := TStringField(aField).Size;
end;

procedure GetFieldTypeMinMax(aField : TField; out aMin, aMax: Double);
begin
  case aField.DataType of
  //  ftUnknown: ;
    ftAutoInc:
    begin
      aMin := 0;
      aMax := MaxInt;  //64bit?
    end;
    ftSmallint:
    begin
      aMin := Low(SmallInt);
      aMax := High(SmallInt);
    end;
    ftInteger:
    begin
      aMin := - MaxInt;
      aMax := MaxInt;
    end;
    ftWord:
    begin
      aMin := Low(Word);
      aMax := High(Word);
    end;
    ftShortint:
    begin
      aMin := Low(ShortInt);
      aMax := High(ShortInt);
    end;
    ftByte:
    begin
      aMin := Low(Byte);
      aMax := High(Byte);
    end;
    ftLongWord:
    begin
      aMin := Low(LongWord);
      aMax := High(LongWord);
    end;
    ftLargeint:
    begin
      aMin := Low(Int64);
      aMax := High(Int64);
    end;
    ftBoolean:
    begin
      aMin := 0;
      aMax := 1;
    end;
    ftCurrency:
    begin
      //Currency  -922337203685477.5808.. 922337203685477.5807  10-20  8
      aMin := -922337203685477.5808;
      aMax := 922337203685477.5807;
    end;
    ftFloat:
    begin
      //Double  5.0e-324 .. 1.7e+308  15-16  8
      aMax := 1.79769313486232E307;// 1.7e+308;
      aMin := - aMax;
    end;
    ftExtended:
    begin
      //Extended  32-bit platforms 3.4e-4932 .. 1.1e+4932
      aMax := 1.79769313486232E307; //3.4e+4932; maakt Delphi +INF van, compileert niet
      aMin := - aMax;
    end;
    ftSingle:
    begin
      //Single  1.5e-45 .. 3.4e+38  7-8  4
      aMax := 1.5e+45;
      aMin := - aMax;
    end;
    ftBCD,
    ftFMTBcd:           //decimal(18,0), numeric(p,s), money(19,4), smallmoney(10,4)     (precision, size)
                        //(19,4): precision = 19 = total length,
                        //      : scale     = 4  = decimals after decimal seperator
                        //        so 19 - 4 = 15 numbers before dot, 4 numbers after dot, total number count = 19
                        //so decimal(18,0) is actually some kind of bigint with no decimals
    begin
      aMin := 0;
      if aField is TBCDField then
      begin
        aMax := TBCDField(aField).Precision - TBCDField(aField).Size;   //(19,4) -> 15
        aMax := Power10(1, Round(aMax)) - 1;     //power(1,6) = 1.000.000 - 1 = 999.999
        aMin := - aMax;
      end
      else
        aMax := 0;  //unknown?
    end;
    ftDate,
    ftTime,
    ftDateTime:
    begin
      aMin := 0;
      aMax := 0;  //skip
    end;
    ftBlob,
    ftMemo,
    ftGraphic,
    ftFmtMemo,
    ftVarBytes,
    ftBytes,
    ftTypedBinary,
    ftWideMemo:
    begin
      aMin := 0;
      if aField is TBlobField then
        aMax := TBlobField(aField).Size            //nvarchar(max0 -> size = 0, nvarchar(50) -> size = 50
      else if aField is TVarBytesField then
        aMax := TVarBytesField(aField).Size
      else
        aMax := 0;   //unknown/infinite
    end;
    ftFixedWideChar,
    ftFixedChar,
    ftWideString,
    ftString:
    begin
      aMin := 0;
      if aField is TStringField then
      begin
        aMax := TStringField(aField).Size;
        if TStringField(aField).FixedChar then
          aMin := aMax;
      end
      else
        aMax := 0;  //unknown
    end;
//    ftParadoxOle: ;
//    ftDBaseOle: ;
//    ftCursor: ;
//    ftADT: ;
//    ftArray: ;
//    ftReference: ;
//    ftDataSet: ;
//    ftOraBlob: ;
//    ftOraClob: ;
//    ftVariant:    Result := ftFieldVariant;
//    ftInterface: ;
//    ftIDispatch: ;
//    ftGuid: ;
//    ftOraTimeStamp: ;
//    ftOraInterval: ;
//    ftConnection: ;
//    ftParams: ;
//    ftStream: ;
//    ftTimeStampOffset: ;
//    ftObject: ;
  else
    //Result := ftFieldUnknown;
    raise Exception.Create('Unsupported type: ' + TypInfo.GetEnumName(TypeInfo(DB.TFieldType), Ord(aField.DataType)) );
  end;
end;

{ TMetaLoader }

class procedure TMetaLoader.FillFieldsForTable(const aTable: TCRUDTable);
var
  connection: TBaseADOConnection;
  mssql: TMSSQLConnection;
  ssql, sfield, s: string;
  field: TCRUDField;
  newfields: TCRUDFieldArray;

  ds: TADODataSet;
  ft: Meta.Data.TFieldType;
  qry: TADOQuery;
  f: TField;
  dbconn: TDBConfig;
  fmin, fmax: Double;
begin
  dbconn := TDBSettings.Instance.GetDBConnection('', dbtNone);  //get specific settings or first in case no dbtype etc
  connection := TDBConnectionPool.GetConnectionFromPool(dbconn) as TBaseADOConnection;

  qry        := TADOQuery.Create(nil);
  ds         := TADODataSet.Create(nil);
  try
    Assert(connection is TMSSQLConnection);
    mssql := (connection as TMSSQLConnection);

    //dummy sql (with no results) to get metadata
    if mssql.IsSQLServerCE then
    begin
      ssql := Format('select * from [%s] where 1 = 2', [aTable.TableName]);  //top does not work with CE?
      with TADOCommand.Create(nil) do
      try
        ConnectionString := mssql.ADOConnection.ConnectionString;
        CommandText   := ssql;
        qry.recordset := Execute;
      finally
        Free;
      end;
      //qry.Recordset := mssql.ADOConnection.Execute(ssql);     does not work?
    end
    else
    begin
      ssql := Format('select top 0 * from %s where 1 = 2', [aTable.TableName]);

      //first use the internal delphi field converion (also for precision handling)
      qry.Connection := mssql.ADOConnection;
      qry.SQL.Text   := ssql;
      try
        qry.Open;
      except on e: exception do
        begin
          s := mssql.ADOConnection.Errors[0].Source;
          s := mssql.ADOConnection.Errors[0].Description;
          s := mssql.ADOConnection.Errors[0].SQLState;
        end;
      end;
    end;

    for f in qry.Fields do
    begin
      field := aTable.FindField(f.FieldName, True{auto create});

      field.FieldName := f.FieldName;
      field.SkipDefault := False;

      if (f.DataType = ftWord) and (field.CustomType = '') then
        field.CustomType := TUltraBooleanField.ClassName;

      if (field.MinValue = 0) and (field.MaxValue = 0) then
      begin
         if f.DataType = ftWord then
         begin
           field.MinValue := 0;
           field.MaxValue := 1;
         end
         else
         begin
           GetFieldTypeMinMax(f, fmin, fmax);
           field.MinValue := fmin;
           field.MaxValue := fmax;
         end;
      end;

      if (field.FieldType = '') then
      begin
        ft := FieldTypeConversion(f.DataType);
        field.FieldType := TypInfo.GetEnumName(TypeInfo(Meta.Data.TFieldType), Ord(ft) );
      end;
      field.Required  := f.Required;
    end;

    //remove old fields
    for field in aTable.Fields do
    begin
      if qry.Fields.FindField(field.FieldName) = nil then
        field.Free
      else
      begin
        SetLength(newfields, Length(newfields)+1);
        newfields[High(newfields)] := field;
      end;
    end;
    aTable.Fields := newfields;

    //low level data conversion (required/nullable fields)
    begin
      ds.Close;
      if mssql.IsSQLServerCE then
      begin
        //strange, does not work with SQL CE
        with TADOCommand.Create(nil) do
        try
          ConnectionString := mssql.ADOConnection.ConnectionString;
          CommandText := 'SELECT * FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''' + aTable.TableName + '''';
          ds.Recordset := Execute;
        finally
          Free;
        end
      end
      else
        mssql.ADOConnection.OpenSchema(siColumns,
                                    VarArrayOf([Unassigned, Unassigned, aTable.TableName]),
                                    EmptyParam, ds);
      ds.First;
      while not ds.Eof do
      begin
        sfield := ds.FieldByName('COLUMN_NAME').AsString;
        field  := aTable.FindField(sfield, False);
        if field <> nil then
        begin
          field.Required := not ds.FieldByName('IS_NULLABLE').AsBoolean;

          if ds.FieldByName('COLUMN_HASDEFAULT').AsBoolean then
          begin
            field.HasDefault := True;			            
            field.DefaultValue := ds.FieldByName('COLUMN_DEFAULT').AsString;
            //((0)) -> 0
            //(getdate())
            while StartsStr('(', field.DefaultValue) do
            begin
              field.DefaultValue := Copy(field.DefaultValue, 2, Length(field.DefaultValue));
              if EndsStr(')', field.DefaultValue) then
                field.DefaultValue := Copy(field.DefaultValue, 1, Length(field.DefaultValue)-1);
            end;
            //('') = ('''') -> ''
            if StartsStr('''', field.DefaultValue) then
              field.DefaultValue := Copy(field.DefaultValue, 2, Length(field.DefaultValue));
            if EndsStr('''', field.DefaultValue) then
              field.DefaultValue := Copy(field.DefaultValue, 1, Length(field.DefaultValue)-1);
            if field.DefaultValue <> '' then
              field.Required := False;
          end
		    else
		      field.HasDefault := False;
        end;

        ds.Next;
      end;
    end;

    //keys: PK + FK's
    ds.Close;
    if mssql.IsSQLServerCE then
    begin
      //strange, does not work with SQL CE
      with TADOCommand.Create(nil) do
      try
        ConnectionString := mssql.ADOConnection.ConnectionString;
        CommandText := 'SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS c ' +
                       'inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE u on u.CONSTRAINT_NAME = c.CONSTRAINT_NAME ' +
                       'where c.CONSTRAINT_TYPE = ''PRIMARY KEY'' and ' +
                       'c.TABLE_NAME = ''' + aTable.TableName + '''';
        ds.Recordset := Execute;
      finally
        Free;
      end
    end
    else
        mssql.ADOConnection.OpenSchema(siPrimaryKeys,
                              VarArrayOf([Unassigned, Unassigned, aTable.TableName]),
                              EmptyParam, ds);
    ds.First;
    while not ds.Eof do
    begin
      sfield := ds.FieldByName('COLUMN_NAME').AsString;
      field  := aTable.FindField(sfield, False);
      if field <> nil then
      begin
        field.IsPK := True;
        field.FieldType := TypInfo.GetEnumName(TypeInfo(Meta.Data.TFieldType), Ord(ftFieldID) );
      end;
      ds.Next;
    end;

    ds.close;
    if mssql.IsSQLServerCE then
    begin
      with TADOCommand.Create(nil) do
      try
        ConnectionString := mssql.ADOConnection.ConnectionString;
        CommandText   := 'SELECT u.TABLE_NAME, u.COLUMN_NAME, u2.TABLE_NAME, u2.COLUMN_NAME ' +
                          'FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS c ' +
                          'inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE u on u.CONSTRAINT_NAME = c.CONSTRAINT_NAME ' +
                          'inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE u2 on u2.CONSTRAINT_NAME = c.UNIQUE_CONSTRAINT_NAME ' +
                          'where u.TABLE_NAME = ''' + aTable.TableName + '''';
        ds.Recordset := Execute;
      finally
        Free;
      end
    end
    else
    begin
      qry.Connection := mssql.ADOConnection;
      ds.CommandText   :=
        Format( 'SELECT o2.name, col_name(fk.fkeyid, fk.fkey) as col2, o.name, col_name(fk.rkeyid, fk.rkey) as col' + #13 +
                'FROM sysobjects o' + #13 +
                'INNER JOIN sysforeignkeys fk on o.id = fk.rkeyid' + #13 +
                'INNER JOIN sysobjects o2 on fk.fkeyid = o2.id' + #13 +
                'WHERE o2.name = ''%s''', [aTable.TableName]);
      ds.Connection := mssql.ADOConnection;
    end;
    ds.Open;
    while not ds.eof do
    begin
      sfield := ds.Fields[1].AsString;
      field  := aTable.FindField(sfield, False);
      if field <> nil then
      begin
        field.IsFK    := True;
        field.FKTable := ds.Fields[2].AsString;
        field.FKField := ds.Fields[3].AsString;
        if (field.FKField <> '') then
         field.MinValue := 0;
      end;
      ds.Next;
    end;

  finally
    TDBConnectionPool.PutConnectionToPool(dbconn, connection);
    qry.Free;
    ds.Free;
  end;
end;

end.
