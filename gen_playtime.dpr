{
  2.x - Future
    What are TTimer good for instead of my TThread.Execute ways

    ? does parameterized query mean i set the text once then prepare etc a lot (would need like 6 query objects)
      close/changeparam/open, instead of changing on query's text so much (which forces prepare to run automatically)?

    ? windowclassname instead if getwindowprocessid??? for rating system wide popup logic

    ? crashes while config open ?
    ? onSongEnd crashing bug ?

    ? check all form creation shit
    ? mem leaks?
    ? (NAH) better keycode selection
    ? (NAH) make config and rating windows popup in better places

  2.0 - Under Development
    Fast ISAM file database for logging
    Rating system logs users rating of songs with song data
    Directory structure changed ../Winamp/Playtime/
    Log filename option replaced by log name in config
    Automatic database repair on corruption
    Automatic creation of directories/databases/ini
    equalizerOn added to logging per listen
    rating added to logging per listen
    logSong has become logSongStart & logSongEnd
    Logging changes to allow determination of song currently playing and more
    Data table versioning
    Configurable rating window hotkey, optionally system wide
    Launch Playtime button in plugin config
    Context help position always fully on screen
    Rating window remembers previous rating when used multiple times per listen

  1.2 - April 19, 2001
    Small interface changes
    Small cleanup changes

  1.1 - April 17, 2001
    Strange file closing change
    Context sensitive help system implemented and better help information given
    Configure dialog will stay on top after selecting logfile in the file dialog

  1.0 - April 16, 2001
    Initial Release
}

library gen_playtime;

uses
  Windows,
  GPFWinAmpControl,
  GPFWinAmpGenericPlugin,
  main in 'main.pas',
  config in 'config.pas',
  sysutils, dialogs; // Exception, showmessage

{$R *.RES}

var GenericPluginInfo : TGPFWinAmpGeneralPurposePlugin;

function winampGetGeneralPurposePlugin : PGPFWinAmpGeneralPurposePlugin; cdecl;
var Plg : TGPFWinAmpGenericPlugin;
begin
  Plg := CreatePluginModule;
  { Initialize description struct }
  GenericPluginInfo.Version := WAGP_VER;
  GenericPluginInfo.Description := PChar(Plg.Description);
  GenericPluginInfo.Init := InitPlugin;
  GenericPluginInfo.Config := ConfigurePlugin;
  GenericPluginInfo.Quit := QuitPlugin;
  Plg.PluginInfo := @GenericPluginInfo;
  Result := @GenericPluginInfo;
end;

exports winampGetGeneralPurposePlugin;

procedure DLLEntryPoint(dwReason:DWORD);
begin
  if dwReason = DLL_PROCESS_DETACH then
    DestroyPluginModule;
end;

begin
TRY
  DllProc := @DLLEntryPoint;
  CreatePluginModule;
EXCEPT on E: Exception do // main try wrapper
  showmessage('Error:Main'+#13#10+E.Message);
END;
end.