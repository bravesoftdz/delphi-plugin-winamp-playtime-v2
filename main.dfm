object playtimeModule: TplaytimeModule
  OldCreateOrder = False
  Left = 225
  Top = 107
  Height = 480
  Width = 696
  object winamp: TGPFWinAmpControl
    WindowClassName = 'Winamp v1.x'
    Plugin = plugin
    Left = 384
    Top = 240
  end
  object plugin: TGPFWinAmpGenericPlugin
    Description = 'Playtime'
    Left = 384
    Top = 296
  end
  object mainSession: TDBISAMSession
    EngineVersion = '2.08'
    KeepConnections = False
    LockRetryCount = 15
    LockWaitTime = 100
    SessionName = 'mainSession'
    LanguageID = 1033
    SortID = 0
    Left = 72
    Top = 168
  end
  object mainDatabase: TDBISAMDatabase
    EngineVersion = '2.08'
    DatabaseName = 'mainDatabase'
    SessionName = 'mainSession'
    Left = 72
    Top = 120
  end
  object tableSong: TDBISAMTable
    AutoDisplayLabels = False
    CopyOnAppend = False
    DatabaseName = 'mainDatabase'
    SessionName = 'mainSession'
    EngineVersion = '2.08'
    Left = 48
    Top = 296
  end
  object tableSession: TDBISAMTable
    AutoDisplayLabels = False
    CopyOnAppend = False
    DatabaseName = 'mainDatabase'
    SessionName = 'mainSession'
    EngineVersion = '2.08'
    Left = 104
    Top = 296
  end
  object query: TDBISAMQuery
    AutoDisplayLabels = False
    CopyOnAppend = False
    DatabaseName = 'mainDatabase'
    SessionName = 'mainSession'
    EngineVersion = '2.08'
    RequestLive = True
    MaxRowCount = -1
    Left = 72
    Top = 232
  end
end
