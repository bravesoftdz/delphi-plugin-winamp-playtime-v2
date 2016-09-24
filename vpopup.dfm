object Popup: TPopup
  Left = 197
  Top = 195
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsToolWindow
  BorderWidth = 8
  Caption = 'Help'
  ClientHeight = 13
  ClientWidth = 88
  Color = clInfoBk
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnDeactivate = FormDeactivate
  PixelsPerInch = 96
  TextHeight = 13
  object labelHint: TLabel
    Left = 0
    Top = 0
    Width = 41
    Height = 13
    Caption = 'labelHint'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    OnClick = labelHintClick
  end
end
