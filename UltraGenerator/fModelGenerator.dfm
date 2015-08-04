object frmModelGenerator: TfrmModelGenerator
  Left = 0
  Top = 0
  Caption = 'frmModelGenerator'
  ClientHeight = 521
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 185
    Top = 0
    Height = 521
  end
  object Splitter1: TSplitter
    Left = 373
    Top = 0
    Height = 521
  end
  object pnlTables: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 521
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    OnResize = pnlTablesResize
    object lbl1: TLabel
      Left = 0
      Top = 0
      Width = 185
      Height = 13
      Align = alTop
      Caption = 'Tables:'
    end
    object grdTables: TStringGrid
      Left = 0
      Top = 13
      Width = 185
      Height = 508
      Align = alClient
      ColCount = 1
      FixedCols = 0
      TabOrder = 0
      OnSelectCell = grdTablesSelectCell
    end
  end
  object pnlFields: TPanel
    Left = 188
    Top = 0
    Width = 185
    Height = 521
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    OnResize = pnlFieldsResize
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 185
      Height = 13
      Align = alTop
      Caption = 'Fields:'
    end
    object grdFields: TStringGrid
      Left = 0
      Top = 13
      Width = 185
      Height = 508
      Align = alClient
      ColCount = 1
      FixedCols = 0
      TabOrder = 0
      OnDblClick = grdFieldsDblClick
    end
  end
  object pnlModel: TPanel
    Left = 376
    Top = 0
    Width = 408
    Height = 521
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    OnResize = pnlModelResize
    object Label2: TLabel
      Left = 0
      Top = 0
      Width = 408
      Height = 13
      Align = alTop
      Caption = 'Model:'
    end
    object grdModel: TStringGrid
      Left = 0
      Top = 13
      Width = 408
      Height = 508
      Align = alClient
      ColCount = 2
      FixedCols = 0
      TabOrder = 0
    end
  end
end
