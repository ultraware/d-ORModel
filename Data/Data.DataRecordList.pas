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
unit Data.DataRecordList;

interface

uses
  Data.DataRecord, Data.Base;

type
  TBaseDataRecordList = class
  protected
    FData: TDataRecord;
    FDataLoaded: Boolean;
    FRows: TRowDataArray;
    FRow: Integer;
    FSharedData: Boolean;

    procedure LoadSharedData(aSingleRecord: TDataRecord);    //single record (e.g from another TDataRecordList)?
  public
    procedure  AfterConstruction; override;
    destructor Destroy; override;

    procedure ClearAll;

    procedure LoadListData(aListData: TRowDataArray);       //dataset
    function  HasDataLoaded: Boolean;
    function  Count: Integer;

    function  HasSharedData: Boolean;

    procedure First;
    function  Next    : Boolean;
    function  Previous: Boolean;
    procedure Last;
    procedure ScrollToRow(aRowNumber: Integer);

    property Data: TDataRecord read FData;
  end;

  TDataRecordList<T: TDataRecord, constructor> = class(TBaseDataRecordList)
  private
    function GetData: T;
  public
    constructor Create; virtual;

    property Data: T read GetData;
  end;

implementation

{ TDataRecordList<T> }

constructor TDataRecordList<T>.Create;
begin
  inherited;
  {$IFDEF VER210}
  FData := TDataRecord(T.Create);
  {$ELSE}
  FData := T.Create as TDataRecord;
  {$ENDIF}
end;

function TDataRecordList<T>.GetData: T;
begin
  {$IFDEF VER210}
  Result := T(FData);
  {$ELSE}
  Result := FData as T;
  {$ENDIF}
end;

{ TBaseDataRecordList }

procedure TBaseDataRecordList.AfterConstruction;
begin
  inherited;
end;

procedure TBaseDataRecordList.ClearAll;
begin
  FSharedData := False;
  FDataLoaded := False;
  FData.LoadRecordData(nil);
  FRows := nil;
  FRow := 0;
end;

function TBaseDataRecordList.Count: Integer;
begin
  Assert(HasDataLoaded);  //exception or -1 in case no data loaded yet (to avoid .count using in for loops without a load)
  Result := Length(FRows);
end;

destructor TBaseDataRecordList.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TBaseDataRecordList.First;
begin
  FRow := 0;
  if Count > 0 then
    FData.LoadRecordData(@FRows[FRow]);
end;

function TBaseDataRecordList.HasDataLoaded: Boolean;
begin
  Result := FDataLoaded;
end;

function TBaseDataRecordList.HasSharedData: Boolean;
begin
  Result := FSharedData;
end;

procedure TBaseDataRecordList.Last;
begin
  FRow := Count - 1;
  if Count > 0 then
    FData.LoadRecordData(@FRows[FRow]);
end;

function TBaseDataRecordList.Next: Boolean;
begin
  Result := False;
  if FRow < Count then
  begin
    Inc(FRow);
    if FRow < Count then
    begin
      Result := True;
      FData.LoadRecordData(@FRows[FRow]);
    end;
  end;
end;

function TBaseDataRecordList.Previous: Boolean;
begin
  if FRow > 0 then
  begin
    Dec(FRow);
    Result := True;
    FData.LoadRecordData(@FRows[FRow]);
  end
  else
    Result := False
end;

procedure TBaseDataRecordList.ScrollToRow(aRowNumber: Integer);
begin
  Assert(Count > aRowNumber);
  Assert(aRowNumber >= 0);
  FRow := aRowNumber;
  FData.LoadRecordData(@FRows[FRow]);
end;

procedure TBaseDataRecordList.LoadListData(aListData: TRowDataArray);
begin
  FRows       := aListData;
  FDataLoaded := True;
  FSharedData := False;
  First;
end;

procedure TBaseDataRecordList.LoadSharedData(aSingleRecord: TDataRecord);
begin
  FRows := nil;
  FDataLoaded := True;
  FSharedData := True;
end;

end.
