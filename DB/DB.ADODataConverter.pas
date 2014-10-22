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
unit DB.ADODataConverter;

interface

uses
  ADOInt, ADODB,
  Data.Base,
  Data.Query, Data.DataRecord;

type
  TADODataConverter = class
  public
    class procedure FillDataByQuery(aADOData: _Recordset; aQuery: IQueryDetails);
    class function  FillFieldArrayByQuery(aADOData: _Recordset; aQuery: IQueryDetails; aFieldCount: Integer): TRowDataArray;
    class function  FillMultiRowArrayByQuery(aADOData: _Recordset; aQuery: IQueryDetails; aFieldCount: Integer): TMultiRowDataArray;
  end;

implementation

{ TADODataConverter }

class procedure TADODataConverter.FillDataByQuery(aADOData: _Recordset;
  aQuery: IQueryDetails);
var
  i: Integer;
  adofields:  Fields;
  fields: TFieldList;
begin
  Assert(aADOData <> nil);
  Assert(aQuery <> nil);
  Assert(aADOData.Fields.Count = aQuery.SelectFields.Count);
  if (aADOData.RecordCount = 0) or   //can be -1 ico server side cursor
     (aADOData.EOF) then Exit;

  adofields := aADOData.Fields;
  fields    := aQuery.SelectFields_Ordered;
  //load data in all fields
  for i := 0 to adofields.Count-1 do
  begin
    fields[i].LoadValue( adofields.Item[i].Value );
  end;
end;

class function TADODataConverter.FillFieldArrayByQuery(aADOData: _Recordset;
  aQuery: IQueryDetails; aFieldCount: Integer): TRowDataArray;
var
  emptyrow: TFieldDataArray;
  prow: PFieldDataArray;
  iRow, iField: Integer;
  f: TBaseField;
  datarecord: TDataRecord;
  v: OLEVariant;
begin
  Result := nil;
  Assert(aADOData <> nil);
  Assert(aQuery <> nil);
  if aQuery.QueryType = qtSelect then
  begin
    Assert(aADOData.Fields.Count = aQuery.SelectFields.Count);
    Assert(aQuery.SelectFields.Count > 0);

    datarecord := aQuery.SelectFields_Ordered[0].DataRecord;
    for f in aQuery.SelectFields_Ordered do
      Assert(datarecord = f.DataRecord, 'all fields must be of same TDataRecord!'); //we fill here multiple TFieldValueArray for TRowValueArray of the same tdatarecord, no suited for mixed/joined models

    if (aADOData.RecordCount > 0) or //can be -1 ico server side cursor
       not aADOData.EOF then
    begin
      if aADOData.RecordCount > 0 then
        SetLength(Result, aADOData.RecordCount);
      iRow := 0;
      while not aADOData.EOF do
      begin
        if Length(Result) <= irow then
          SetLength(Result, irow+1);

        emptyrow     := AllocFieldValueArray(aFieldCount);
        Result[iRow].FieldValues := emptyrow;
        prow         := @Result[iRow].FieldValues;

        for iField := 0 to aQuery.SelectFields_Ordered.Count-1 do
        //for iField := 0 to aADOData.Fields.Count-1 do
        begin
          f := aQuery.SelectFields_Ordered[iField];
          //fast direct load value into array
          prow^[f.Position].DataType := f.FieldType;
          prow^[f.Position].LoadValue( aADOData.Fields[iField].Value );
        end;

        aADOData.MoveNext;
        inc(iRow);
      end;
    end;
  end
  else if aQuery.QueryType = qtInsert then
  begin
    if aADOData.State = adStateClosed then
      aADOData := aADOData.NextRecordset(v);

    Assert(aADOData.Fields.Count = 1);
    if (aADOData.RecordCount > 0) or //can be -1 ico server side cursor
       not aADOData.EOF then
    begin
      if aADOData.RecordCount > 0 then
        SetLength(Result, aADOData.RecordCount);
      iRow := 0;
      while not aADOData.EOF do
      begin
        if Length(Result) <= irow then
          SetLength(Result, irow+1);

        emptyrow     := AllocFieldValueArray(aFieldCount);
        Result[iRow].FieldValues := emptyrow;
        prow         := @Result[iRow].FieldValues;

        f := aQuery.MainTableField;
        //fast direct load value into array
        prow^[f.Position].DataType := f.FieldType;
        prow^[f.Position].LoadValue( aADOData.Fields[0].Value );

        aADOData.MoveNext;
        inc(iRow);
      end;
    end;
  end
  else
    Assert(False);
end;

class function TADODataConverter.FillMultiRowArrayByQuery(aADOData: _Recordset; aQuery: IQueryDetails;
  aFieldCount: Integer): TMultiRowDataArray;
var
  emptyrow: TFieldDataArray;
  prow: PFieldDataArray;
  iRow, iField: Integer;
  f: TBaseField;
begin
  Result := nil;
  Assert(aADOData <> nil);
  Assert(aQuery <> nil);
  Assert(aADOData.Fields.Count = aQuery.SelectFields.Count);
  Assert(aQuery.SelectFields.Count > 0);

  if (aADOData.RecordCount > 0) or //can be -1 ico server side cursor
     not aADOData.EOF then
  begin
    if aADOData.RecordCount > 0 then
      SetLength(Result, aADOData.RecordCount);
    iRow := 0;
    while not aADOData.EOF do
    begin
      if Length(Result) <= irow then
        SetLength(Result, irow+1);

      emptyrow     := AllocFieldValueArray(aFieldCount);
      //note: only direct data is filled (.RowData), not the data of sub rows (done via lazy load)
      Result[iRow].RowData.FieldValues := emptyrow;
      prow         := @Result[iRow].RowData.FieldValues;

      for iField := 0 to aQuery.SelectFields_Ordered.Count-1 do
      begin
        f := aQuery.SelectFields_Ordered[iField];
        //fast direct load value into array
        prow^[f.Position].DataType := f.FieldType;
        prow^[f.Position].LoadValue( aADOData.Fields[iField].Value );
      end;

      aADOData.MoveNext;
      inc(iRow);
    end;
  end;
end;

end.
