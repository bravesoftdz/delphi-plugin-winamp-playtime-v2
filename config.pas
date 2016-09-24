unit config;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms,
  inifiles, // duh
  shellapi, // shellexecute
  filectrl, // directoryexists
  messages, // message handling (wmhelp)
  vpopup, // my popup
  Mask, StdCtrls, Graphics, ExtCtrls;

type
  TconfigForm = class(TForm)
    editHeartbeat: TMaskEdit;
    editHeartbeatMin: TMaskEdit;
    buttonOK: TButton;
    buttonDefaults: TButton;
    groupMainSettings: TGroupBox;
    infoPanel: TPanel;
    iconImage: TImage;
    labelCopyright: TLabel;
    linkWeb: TLabel;
    linkEmail: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    editLogname: TEdit;
    buttonLaunch: TButton;
    groupRatingSettings: TGroupBox;
    Label4: TLabel;
    checkSystemWide: TCheckBox;
    editKey: TMaskEdit;
    linkAdvanced: TLabel;
    Label5: TLabel;

    procedure FormCreate(Sender: TObject);

    procedure readINI;
    procedure saveINI;
    procedure setDefaultGlobals;
    procedure populateForm;
    procedure populateGlobals;
    procedure buttonDefaultsClick(Sender: TObject);
    procedure buttonOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure linkWebClick(Sender: TObject);
    procedure linkEmailClick(Sender: TObject);
    procedure buttonLaunchClick(Sender: TObject);
    procedure linkAdvancedClick(Sender: TObject);

  private
    procedure WMHelp(var Message: TWMHelp); Message WM_Help;

  public
    keyList : TStrings;
  end;

var
  configForm : TConfigForm;

implementation

{$R *.DFM}

uses main;

procedure TconfigForm.FormCreate(Sender: TObject);
begin

  labelCopyright.Caption := 'Playtime Winamp Plugin ('+format('%n',[main.playtimeVersion/100])+')'+#13#10+'Copyright © 2001 ------';

  readINI;
  populateForm; // from globals

end;

procedure TconfigForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  populateGlobals; // from form
  saveINI;
end;

procedure TconfigForm.readINI;
var
  ini : TMemIniFile;
begin

  // set defaults for global config vars
  setDefaultGlobals;

  // if exists, read ini & set global config vars
  if (fileexists(main.fileIni)) then
  begin
    ini := TMemIniFile.Create(main.fileIni);

    main.logname:=ini.readstring('plugin','logname',main.logname);

    main.heartbeatConst:=ini.readinteger('plugin','heartbeat',main.heartbeatConst);
    main.heartbeatMinConst:=ini.readinteger('plugin','heartbeatMin',main.heartbeatMinConst);
    main.rateShortcut:=ini.readinteger('plugin','rateShortcut',main.rateShortcut);
    main.rateSystemWide:=ini.readbool('plugin','rateSystemWide',main.rateSystemWide);

    ini.free
  end
  // else, write ini with defaults
  else
    saveINI;
  begin

  end;

end;

procedure TconfigForm.saveINI;
var
  ini : TMemIniFile;
begin
  // force the directory structure
  forcedirectories(dirPlaytime);

  ini := TMemIniFile.Create(main.fileIni);

  // write current globals to INI
  ini.writestring('plugin','logname',main.logname);

  ini.writeinteger('plugin','heartbeat',main.heartbeatConst);
  ini.writeinteger('plugin','heartbeatMin',main.heartbeatMinConst);
  ini.writeinteger('plugin','rateShortcut',main.rateShortcut);
  ini.writebool('plugin','rateSystemWide',main.rateSystemWide);

  ini.UpdateFile;
  ini.Free;

end;

procedure TconfigForm.setDefaultGlobals;
begin

  // user configurable pseudo consts loaded at runtime
  main.logname := 'log';  // pseudo const, user configurable, runtime ini

  // user configurable pseudo consts loaded each new song
  main.heartbeatConst := 1000; // pseudo const, user configurable, 1000 is probably ideal, 500 might work, though higher will sometimes be needed, see heartbeat quirks
  main.heartbeatMinConst := 1; // pseudo const, user configurable, 1 should be the lowest value possible

  // loaded immediately
  main.rateShortcut := 9;
  main.rateSystemWide := false;

end;

// populate form from globals
procedure TconfigForm.populateForm;
begin

  editLogname.Text:=main.logname;

  editHeartbeat.Text:=inttostr(main.heartbeatConst);
  editHeartbeatMin.Text:=inttostr(main.heartbeatMinConst);

  editKey.text := inttostr(main.rateShortcut);
  checkSystemWide.checked := main.rateSystemWide;

end;

// populate globals from form
procedure TconfigForm.populateGlobals;
begin

  main.logname:=editLogname.Text;

  main.heartbeatConst:=strtoint(editHeartbeat.Text);
  main.heartbeatMinConst:=strtoint(editHeartbeatMin.Text);

  main.rateShortcut:=strtoint(editKey.text);
  main.rateSystemWide:=checkSystemWide.checked;

end;

procedure TconfigForm.buttonDefaultsClick(Sender: TObject);
begin

  setDefaultGlobals;
  populateForm;

end;

procedure TconfigForm.buttonOKClick(Sender: TObject);
begin
  close;
end;

procedure TconfigForm.linkWebClick(Sender: TObject);
begin
  ShellExecute(0, Nil, 'http://---.org/?software', Nil, Nil, SW_NORMAL);
end;

procedure TconfigForm.linkEmailClick(Sender: TObject);
begin
  ShellExecute(0, Nil, PChar('mailto:software@---.org?subject=gen_playtime '+inttostr(main.playtimeversion)+' ('+inttostr(main.winampversion)+')'), Nil, Nil, SW_NORMAL);
end;

procedure TconfigForm.buttonLaunchClick(Sender: TObject);
begin
  ShellExecute(0, Nil, PChar(main.fileEXE), Nil, Nil, SW_NORMAL);
end;

procedure TconfigForm.WMHelp(var Message: TWMHelp);
var
  control: TWinControl;
begin
  control:=findcontrol(Message.HelpInfo.hItemHandle);
  TPopup.showpopup(control.Hint);
end;

procedure TconfigForm.linkAdvancedClick(Sender: TObject);
begin
  ShellExecute(0, Nil, 'http://msdn.microsoft.com/library/psdk/winui/vkeys_529f.htm', Nil, Nil, SW_NORMAL);
end;

end.
