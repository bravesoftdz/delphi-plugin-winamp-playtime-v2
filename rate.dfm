object rateForm: TrateForm
  Left = 324
  Top = 263
  ActiveControl = rateBox
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Playtime Winamp Plugin'
  ClientHeight = 177
  ClientWidth = 161
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object groupRating: TGroupBox
    Left = 8
    Top = 8
    Width = 145
    Height = 161
    Caption = 'Your Song Rating'
    TabOrder = 2
    object labelTitle: TLabel
      Left = 56
      Top = 81
      Width = 78
      Height = 52
      Caption = 'labelTitledfg dggh d dd  f fg gfgdfdfh  dfhdfh df'
      Transparent = True
      WordWrap = True
    end
    object rateBox: TCheckListBox
      Left = 8
      Top = 16
      Width = 41
      Height = 137
      OnClickCheck = rateBoxClickCheck
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      Items.Strings = (
        '10'
        ' 9'
        ' 8'
        ' 7'
        ' 6'
        ' 5'
        ' 4'
        ' 3'
        ' 2'
        ' 1')
      ParentFont = False
      TabOrder = 0
      OnClick = rateBoxClick
    end
  end
  object buttonRate: TButton
    Left = 64
    Top = 24
    Width = 81
    Height = 25
    Caption = 'Rate'
    Default = True
    TabOrder = 0
    OnClick = buttonRateClick
  end
  object buttonCancel: TButton
    Left = 64
    Top = 56
    Width = 81
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = buttonCancelClick
  end
  object rateDatabase: TDBISAMDatabase
    EngineVersion = '2.08'
    DatabaseName = 'rateDatabase'
    SessionName = 'rateSession'
    Left = 64
    Top = 160
  end
  object rateSession: TDBISAMSession
    EngineVersion = '2.08'
    KeepConnections = False
    LockRetryCount = 15
    LockWaitTime = 100
    SessionName = 'rateSession'
    LanguageID = 1033
    SortID = 0
    Left = 96
    Top = 160
  end
  object rateTableSong: TDBISAMTable
    AutoDisplayLabels = False
    CopyOnAppend = False
    DatabaseName = 'rateDatabase'
    SessionName = 'rateSession'
    EngineVersion = '2.08'
    Top = 160
  end
  object query: TDBISAMQuery
    AutoDisplayLabels = False
    CopyOnAppend = False
    DatabaseName = 'rateDatabase'
    SessionName = 'rateSession'
    EngineVersion = '2.08'
    RequestLive = True
    MaxRowCount = -1
    Left = 32
    Top = 160
  end
end
