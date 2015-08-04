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
unit fModelGenerator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls;

type
  TfrmModelGenerator = class(TForm)
    pnlTables: TPanel;
    lbl1: TLabel;
    grdTables: TStringGrid;
    spl1: TSplitter;
    pnlFields: TPanel;
    Label1: TLabel;
    grdFields: TStringGrid;
    Splitter1: TSplitter;
    pnlModel: TPanel;
    Label2: TLabel;
    grdModel: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure pnlTablesResize(Sender: TObject);
    procedure pnlFieldsResize(Sender: TObject);
    procedure pnlModelResize(Sender: TObject);
    procedure grdFieldsDblClick(Sender: TObject);
  private
  public
    class procedure CreateAndShowModal;
  end;

implementation

uses
  Data.CRUDSettings;

{$R *.dfm}

procedure TfrmModelGenerator.FormCreate(Sender: TObject);
var
  tbl: TCRUDTable;
  irow: Integer;
begin
  grdTables.RowCount  := 1;
  grdTables.RowCount  := 2;
  grdTables.Cells[0, 0] := 'Tablename';
  grdTables.FixedRows := 1;
  grdTables.RowCount  := grdTables.FixedRows + CRUDSettings.TableCount;

  irow := grdTables.FixedRows;
  for tbl in CRUDSettings.Tables do
  begin
    grdTables.Cells  [0, irow] := tbl.TableName;
    grdTables.Objects[0, irow] := tbl;
    Inc(irow);
  end;

  grdModel.RowCount  := 1;
  grdModel.RowCount  := 2;
  grdModel.Cells[0, 0] := 'Table';
  grdModel.Cells[0, 0] := 'Fieldname';
  grdModel.FixedRows := 1;
end;

procedure TfrmModelGenerator.grdFieldsDblClick(Sender: TObject);
var
  tbl: TCRUDTable;
  f: TCRUDField;
  irow: Integer;
begin
  tbl := grdTables.Objects[0, grdTables.Row] as TCRUDTable;
  f   := grdFields.Objects[0, grdFields.Row] as TCRUDField;

  grdModel.Cells[0, 0] := 'Table';
  grdModel.Cells[0, 0] := 'Fieldname';
  grdModel.FixedRows := 1;
  grdModel.RowCount  := grdModel.RowCount + 1;

  irow := grdModel.RowCount - 1;
  grdModel.Cells  [0, irow] := tbl.TableName;
  grdModel.Cells  [1, irow] := f.FieldName;
  grdModel.Objects[0, irow] := f;
end;

procedure TfrmModelGenerator.grdTablesSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  tbl: TCRUDTable;
  f: TCRUDField;
  irow: Integer;
begin
  tbl := grdTables.Objects[0, ARow] as TCRUDTable;

  grdFields.RowCount  := 1;
  grdFields.RowCount  := 2;
  grdFields.Cells[0, 0] := 'Fieldname';
  grdFields.FixedRows := 1;
  grdFields.RowCount  := grdFields.FixedRows + tbl.FieldCount;

  irow := grdFields.FixedRows;
  for f in tbl.Fields do
  begin
    grdFields.Cells  [0, irow] := f.FieldName;
    grdFields.Objects[0, irow] := f;
    Inc(irow);
  end;
end;

procedure TfrmModelGenerator.pnlFieldsResize(Sender: TObject);
begin
  grdFields.ColWidths[0] := pnlFields.Width - 25;
end;

procedure TfrmModelGenerator.pnlModelResize(Sender: TObject);
begin
  grdModel.ColWidths[0] := (pnlModel.Width - 25) div 2;
  grdModel.ColWidths[1] := (pnlModel.Width - 25) div 2;
end;

procedure TfrmModelGenerator.pnlTablesResize(Sender: TObject);
begin
  grdTables.ColWidths[0] := pnlTables.Width - 25;
end;

class procedure TfrmModelGenerator.CreateAndShowModal;
var f: TfrmModelGenerator;
begin
  f := Self.Create(nil);
  try
    f.ShowModal;
  finally
    f.Free;
  end;
end;

end.
