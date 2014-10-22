object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'UltraGenerator'
  ClientHeight = 351
  ClientWidth = 774
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 185
    Top = 33
    Height = 318
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 774
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnLoadTables: TButton
      Left = 3
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Load Tables'
      TabOrder = 0
      OnClick = btnLoadTablesClick
    end
    object btnGenerate: TButton
      Left = 272
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Generate all'
      TabOrder = 1
      OnClick = btnGenerateClick
    end
    object pbGenerate: TProgressBar
      Left = 353
      Top = 7
      Width = 150
      Height = 17
      TabOrder = 2
      Visible = False
    end
    object btnSaveXML: TButton
      Left = 84
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Save XML'
      TabOrder = 3
      OnClick = btnSaveXMLClick
    end
    object Button1: TButton
      Left = 616
      Top = 2
      Width = 113
      Height = 25
      Caption = 'Model generator'
      TabOrder = 4
      OnClick = Button1Click
    end
    object btnDeps: TButton
      Left = 188
      Top = 3
      Width = 78
      Height = 25
      Caption = 'Dependencies'
      TabOrder = 5
      OnClick = btnDepsClick
    end
  end
  object pnl1: TPanel
    Left = 0
    Top = 33
    Width = 185
    Height = 318
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    OnResize = pnl1Resize
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
      Height = 305
      Align = alClient
      ColCount = 1
      FixedCols = 0
      TabOrder = 0
      OnSelectCell = grdTablesSelectCell
    end
  end
  object pnl2: TPanel
    Left = 188
    Top = 33
    Width = 586
    Height = 318
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblFields: TLabel
      Left = 0
      Top = 0
      Width = 586
      Height = 13
      Align = alTop
      Caption = 'Fields:'
    end
    object grdFields: TStringGrid
      Left = 0
      Top = 46
      Width = 586
      Height = 272
      Align = alClient
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing]
      TabOrder = 0
      OnGetEditText = grdFieldsGetEditText
      OnSelectCell = grdFieldsSelectCell
      OnSetEditText = grdFieldsSetEditText
    end
    object cmbxCustomType: TComboBox
      Left = 157
      Top = 200
      Width = 145
      Height = 21
      Style = csDropDownList
      DropDownCount = 25
      ItemIndex = 0
      TabOrder = 1
      Text = 'Customtype'
      OnSelect = cmbxCustomTypeSelect
      Items.Strings = (
        'Customtype')
    end
    object Panel2: TPanel
      Left = 0
      Top = 13
      Width = 586
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
      object btnGenerateTable: TButton
        Left = 4
        Top = 4
        Width = 93
        Height = 25
        Caption = 'Generate table'
        TabOrder = 0
        OnClick = btnGenerateTableClick
      end
      object btnGenerateBO: TButton
        Left = 100
        Top = 4
        Width = 93
        Height = 25
        Caption = 'Generate BO'
        TabOrder = 1
        OnClick = btnGenerateBOClick
      end
    end
    object cbbTypeCmbx: TComboBox
      Left = 6
      Top = 200
      Width = 145
      Height = 21
      Style = csDropDownList
      DropDownCount = 25
      ItemIndex = 0
      TabOrder = 3
      Text = 'Veld Type'
      OnSelect = cbbTypeCmbxSelect
      Items.Strings = (
        'Veld Type')
    end
    object cbbSkipDefault: TComboBox
      Left = 438
      Top = 200
      Width = 145
      Height = 21
      DropDownCount = 20
      ItemIndex = 0
      TabOrder = 4
      Text = 'SkipDefault'
      OnSelect = cbbSkipDefaultSelect
      Items.Strings = (
        'SkipDefault')
    end
  end
end
