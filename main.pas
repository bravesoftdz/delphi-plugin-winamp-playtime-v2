unit main;

interface

uses
  Windows,
  Forms, // TDataModule
  dialogs, // showmessage
  Classes,
  SysUtils, // extractfiledir
  FileCtrl, // forcedirectories
  shellapi, // shellexecute
  GPFWinAmpControl,
  GPFWinAmpGenericPlugin, Db, DBISAMTb, dbisamen;

type
  // this record only stores stuff we need to know to run, all other stuff has been removed and logs directly into the database as the first step in allowing the current playing song to be known
  TplaylistSong = record

    id : integer;     // not logged per se
    rating : integer; // not logged per se

    heartbeatCount : integer; // set to 0 in onSongStart, changed each heartbeat
    // songs fetch the constants for themselves when they start in case the constant changes mid-song. In that case, the current song uses its own vars it fetched in heartbeatMin, the next song will fetch the updated consts
    heartbeat : integer; // this is also set before the while in Execute just so it knows for the first loop
    heartbeatMin : integer;

    title : string;
    filename : string; // set in onSongStart and before the while in Execute, probably doesnt have to be reset in hearbeatMin frame, but might as well

    timestampStart : TDateTime; // set in
    timestampEnd : TDateTime; // set in onSongEnd

    filetype: longword;

  end;

  TplaytimeModule = class(TDataModule)
    winamp: TGPFWinAmpControl;
    plugin: TGPFWinAmpGenericPlugin;
    mainDatabase: TDBISAMDatabase;
    mainSession: TDBISAMSession;
    tableSong: TDBISAMTable;
    tableSession: TDBISAMTable;
    query: TDBISAMQuery;
  end;

  TplaytimeThread = class(TThread)
    procedure Execute; override;
    private
      procedure onSameSong;
      procedure onNewSong;
      procedure onSongStart;
      procedure onSongEnd;
      procedure logSongStart;
      procedure logSongEnd;
      procedure logSessionStart;
      procedure logSessionEnd;
      procedure initDB; // called before main heartbeat loop
      procedure openTable(tbl: TDBISAMTable); // Only called by initDB
      procedure closeDB; // called after main heartbeat loop

      procedure initSongTable;
      procedure initSessionTable;

    public

      song : TplaylistSong;

  end;

  TrateThread = class(TThread)
    procedure Execute; override;
    private
      procedure launchRatings;
  end;

var
  m : TplaytimeModule;
  playtimeThread : TplaytimeThread;
  rateThread : TrateThread;

  winampVersion : integer;
  playtimeVersion : integer;

  sessionID : integer;

  // songs fetch theirs from here, so that when it is changed in the config, the current song will still use it's own, the next song however will use the new value it fetches on onSongStart
  heartbeatConst : integer;
  heartbeatMinConst : integer;

  rateShortcut : integer;
  rateSystemWide : boolean;

  logname : string; // true constant, runtime ini

  dirWinamp : string; // true constant, runtime
  dirPlaytime : string; // true constant, runtime

  // macros determined by above constants
  fileIni : string;
  fileExe : string;
  fileRate: string;

  function CreatePluginModule : TGPFWinAmpGenericPlugin;
  procedure DestroyPluginModule;
  function InitPlugin : Integer; cdecl;
  procedure ConfigurePlugin; cdecl;
  procedure QuitPlugin; cdecl;

implementation

{$R *.DFM}

uses
  config, rate;

function CreatePluginModule : TGPFWinAmpGenericPlugin;
begin
  if not Assigned(m) then
    m := Tplaytimemodule.Create(nil);
  Result := m.plugin;
end;

procedure DestroyPluginmodule;
begin
  if Assigned(m) then
    m.Free;
  m := nil;
end;

function InitPlugin;
begin
  // create threads
  playtimeThread := TplaytimeThread.Create(false);
  rateThread := TrateThread.Create(false);
  Result := 0; // part of GPF
end;

procedure ConfigurePlugin;
begin
  configForm := TconfigForm.CreateParented(m.winamp.hwindow);
  configForm.showmodal;
  configForm.free;
end;

procedure QuitPlugin;
begin
  // stop the threads
  playtimeThread.Terminate;
  playtimeThread.WaitFor;
  playtimeThread.Free;
  rateThread.Terminate;
  rateThread.WaitFor;
  rateThread.Free;
end;

//==============================================================================
// TplaytimeThread
procedure TplaytimeThread.Execute;
begin
TRY // main try wrapper

  // pseudo const, set at runtime
  winampVersion := m.winamp.Version;
  playtimeVersion := 200;
  // 199 (hellbound)

  // get global config vars
  dirWinamp := extractfiledir(paramstr(0));
  dirPlaytime := dirWinamp + '\Playtime';
  fileIni := dirPlaytime + '\playtime.ini';
  fileExe := dirPlaytime + '\playtime.exe';
  fileRate:= dirPlaytime + '\ratesong.exe';
  configForm.readINI;

  song.heartbeat := heartbeatConst; // so we know how long to sleep before onSongStart sets song.heartbeat
  song.filename := '';

  // setup DB, create it if it doesn't exist, etc
  initDB;

  logSessionStart;

  song.heartbeatcount := 0; // init before loop
  song.heartbeatmin := main.heartbeatminConst; // init before loop
  while not(Terminated) do
  begin

    // QUIRK : Each iteration of this loop does not take song.heartbeat milliseconds, because of this, when you have listened to a full song the heartbeatCount can be 1 or 2 less than the number of heartbeats in a song. There will have to be parser options for this 'close enough' stuff I guess.
    sleep(song.heartbeat);

    if (m.winamp.playbackstatus = wapsPlaying) then
    begin
      // if same song playing as last heartbeat
      if (m.winamp.PlaylistFilename[m.winamp.PlaylistIndex] = song.filename) then
        OnSameSong
      // else different song than last heartbeat
      else
        OnNewSong;
    end;

  end; // while

  OnSongEnd;

  logSessionEnd;

  closeDB;

EXCEPT on E: Exception do // main try wrapper
  showmessage('Error:Execute'+#13#10+E.Message);
END;
end;

// same song as last heartbeat
procedure TplaytimeThread.onSameSong;
begin

  // increment song.heartbeatCount
  song.heartbeatCount:=song.heartbeatCount + 1;

  // HAX : get title every beat so we have the best title on the last beat of this song
  //       this is merely to allow us to get the best possible title for STREAMS & CDDB queried CD's
  //       If this becomes a speed problem, we can always just do it every 5 beats etc
  // May as well do it for everything, never know, perhaps use song.drivetype and song.filetype later to only do it on streams and cd's
  song.title := m.winamp.PlaylistTitle[m.winamp.PlaylistIndex];

  // if this song has been playing heartbeatMin beats, then logSongStart
  if (song.heartbeatCount = song.heartbeatMin) then
    logSongStart; // try this here, 0th heartbeat is close, 1st seems to work well, seem Heartbeat Quirks

end;

// different song than last heartbeat
procedure TplaytimeThread.onNewSong;
begin

  // QUIRK : OnNewSong will NOT trigger is a user plays Track 1.cda in a cd then plays Track 1.cda on a different cd, it will think they are the same song
    // TODO : Can probably change this by using filename//title as the unique identifier
    //        Ooo, but that would mean a song would get logged twice if the user edited it's ID3 while it was playing! Maybe thats a good thing...?
    //        Might be possible just to do it for CD only? Do I even really care?
    //        Using a second identifier other than title might work... size? date?
  // QUIRK : Streams are always 'playing' even if you have typed a bad stream address, because of this, bad streams (no connect) are logged

  if fileexists(song.filename) // we check if fileexists onNewSong to skip entries in the playlist that do not exist on the drive anymore
    or (song.filename = '') // we check if filename onNewSong is '' otherwise we would never get in because '' is the initial value of the filename when winamp starts
    or (song.filetype = FILE_TYPE_UNKNOWN) // we check if stream onNewSong is true otherwise we wouldn't get in because a stream will always fail fileexists (Remember onNewSong ends the old song as well, and thats what this point has to deal with)
    then
  begin

    // if last song was fake, this is the first song
    if (song.filename = '') then
    begin
      // OnFirstSong is not actually defined yet, no use for it
    end
    else // else last song was real
    begin
      OnSongEnd; // old song ended
    end;

    OnSongStart; // new song started

  end;

end;

// new song started
procedure TplaytimeThread.onSongStart;
begin

  // get the current consts when a song is started
  song.heartbeat := heartbeatConst;
  song.heartbeatMin := heartbeatMinConst;

  song.heartbeatCount := 0;

  song.filename := m.winamp.PlaylistFilename[m.winamp.PlaylistIndex];
  song.timestampStart := Now;

end;

// old song ended
procedure TplaytimeThread.onSongEnd;
begin

  // this if prevents the out of loop OnSongEnd from logging an empty entry when someone opens and closes winamp without playing
  if not(song.filename = '') then
  begin
    // set timestampEnd
    song.timestampEnd := Now;

    // if song was played at least heartbeatMin beats, then logSongEnd
    if (song.heartbeatCount >= song.heartbeatMin) then
      logSongEnd;
  end;

end;

procedure TplaytimeThread.logSongStart;
var
  h: integer;
  tracklength: integer;
  filesize: integer;
  filedate: TDateTime;
begin

  // song.filename - set here, logged now
  // song.title - set here and changing, logged now and later
  song.filename := m.winamp.PlaylistFilename[m.winamp.PlaylistIndex]; // this is set before heartbeatMin, but we may as well set it here again just in case of something weird
  song.title    := m.winamp.PlaylistTitle[m.winamp.PlaylistIndex];
  // song.heartbeat - set already, logged now
  // song.heartbeatMin - set already, logged now
  // song.heartbeatCount - set already and changing, logged later
  // song.timestampstart - set already, logged now
  // song.id - set below, logged automatically
  // song.rating - init here and logged/set rating window
  song.rating   := 0;
  // song.filetype - set below, logged now
  // song.timestampend - set later, logged later

  with m.query do
  begin
    sql.text :=
      'insert into song (filename,sessionid,start,title,bitrate,samplerate,channels,filesize,filedate,filetype,drivetype,tracklength,playlistIndex,playlistCount,skin,shuffleOn,repeatOn,internetOn,equalizerOn,heartbeat,heartbeatMin)'+
      'values(:filename,:sessionid,:start,:title,:bitrate,:samplerate,:channels,:filesize,:filedate,:filetype,:drivetype,:tracklength,:playlistIndex,:playlistCount,:skin,:shuffleOn,:repeatOn,:internetOn,:equalizerOn,:heartbeat,:heartbeatMin)';

    parambyname('sessionid').asInteger := sessionID;

    parambyname('start').asDateTime := song.timestampStart;
    parambyname('filename').asMemo := song.filename;
    parambyname('title').asMemo := song.title;
    parambyname('heartbeat').asInteger := song.heartbeat;
    parambyname('heartbeatMin').asInteger := song.heartbeatMin;

    parambyname('shuffleOn').asBoolean := m.winamp.shuffleOn;
    parambyname('repeatOn').asBoolean := m.winamp.repeatOn;
    parambyname('internetOn').asBoolean := m.winamp.internet;
    parambyname('equalizerOn').asBoolean := m.winamp.EQenabled;

    parambyname('bitrate').asInteger := m.winamp.TrackBitrate;
    parambyname('samplerate').asInteger := m.winamp.TrackSamplerate;
    parambyname('channels').asInteger := m.winamp.TrackChannels;

    parambyname('playlistIndex').asInteger := m.winamp.PlaylistIndex+1;
    parambyname('playlistCount').asInteger := m.winamp.PlaylistCount;

    parambyname('drivetype').asInteger := GetDriveType(PChar(ExtractFileDrive(song.filename)));

    parambyname('skin').asMemo := m.winamp.Skin;

  end;

  // fileopen to get date (sees streams) (uses win32 createfile)
  h := fileopen(song.filename,fmShareDenyNone);

  // QUIRK: In some other code of mine...getfiletype would return FILE_TYPE_UNKNOWN for streams
  if (h = -1) then   // fileopen failed, so, let's set filetype to unknown (streams do this)
    song.filetype := FILE_TYPE_UNKNOWN
  else // else fileopen worked, set filetype
    song.filetype := GetFileType(h);

  // QUIRK : filedate seems off compared to dos/explorer date, no one really knows why. This is probably fine since Delphi gets the same (slightly off) timestamp for each file and Delphi is all that will be used. 3rd party parsers could have a problem with it, but there probably won't even be any :p
  // if unknown
  if song.filetype = FILE_TYPE_UNKNOWN then
  begin
    tracklength  := -1;
    filesize     := -1;
    filedate     := -1;
  end
  else
  begin
    tracklength  := m.winamp.TrackLength;
    filesize     := GetFileSize(h,nil);
    filedate     := FileDateToDateTime(FileGetDate(h));
  end;

  // close file, this seems to even even work for FILE_TYPE_UNKNOWN and h = -1
  fileclose(h);

  // filetype, tracklength, filesize, filedate ready now
  with m.query do
  begin
    parambyname('filetype').asInteger := song.filetype;
    parambyname('tracklength').asInteger := tracklength;
    parambyname('filesize').asInteger := filesize;
    parambyname('filedate').asDateTime := filedate;

    execsql;
  end;

  // set the id of what we just inserted
  song.id:=m.tableSong.lastAutoIncValue;

end;

procedure TplaytimeThread.logSongEnd;
begin

  with m.query do
  begin
    sql.text := 'update song set title = :title, heartbeatCount = :heartbeatCount, end = :end where id = :id';

    parambyname('title').asString := song.title;
    parambyname('heartbeatCount').asInteger := song.heartbeatCount;
    parambyname('end').asDatetime := song.timestampEnd;
    parambyname('id').asInteger := song.id;

    execsql;
  end;

end;

procedure TplaytimeThread.logSessionStart;
var
  insertedStamp : TDateTime;
begin

  m.query.sql.text :=
    'insert into session (start,winampVersion,playtimeVersion)'+
    'values (:start,:winampVersion,:playtimeVersion)';

  insertedStamp := now;
  with m.query do
  begin
    parambyname('start').asDatetime := insertedStamp;
    parambyname('winampVersion').asInteger := winampVersion;
    parambyname('playtimeVersion').asInteger := playtimeVersion;

    execsql;
  end;

  // set the session id of what we just inserted
  sessionID:=m.tableSession.lastAutoIncValue;

end;

procedure TplaytimeThread.logSessionEnd;
begin

  // set end time for this sessionid
  with m.query do
  begin
    sql.text := 'update session set end = :end where id = :sessionid';

    parambyname('end').asDateTime := now;
    parambyname('sessionid').asInteger := sessionID;

    execsql;
  end;

end;

procedure TplaytimeThread.closeDB;
begin

  with m do
  begin
    tableSong.close;
    tableSession.close;
    query.close;

    tableSong.free;
    tableSession.free;
    query.free;
  end;

end;

procedure TplaytimeThread.openTable(tbl: TDBISAMTable);
begin

  try //Supposedly AUTO REPAIR on OPEN...
    tbl.Open;
  except
    on E : Exception do
      if (E is EDBISAMEngineError) then
        case EDBISAMEngineError(E).Errors[0].ErrorCode of
DBISAM_ENDOFBLOB,DBISAM_HEADERCORRUPT,DBISAM_FILECORRUPT,
DBISAM_MEMOCORRUPT,DBISAM_INDEXCORRUPT,
DBISAM_READERR,DBISAM_WRITEERR,DBISAM_INVALIDBLOBOFFSET,
DBISAM_INVALIDIDXDESC,DBISAM_INVALIDBLOBLEN:
          begin
            tbl.RepairTable;
            tbl.Open;
          end;
        end
      else
        raise;
    else
      raise;
  end;

end;

procedure TplaytimeThread.initDB;
begin

  // TODO : must have r/w access to logdir...
  // force the directory structure
  forcedirectories(dirPlaytime+'\'+logname);

  // set directory for database component, dont set databasename on query?
  m.mainDatabase.Directory:=dirPlaytime + '\' +logname;
  m.mainSession.PrivateDir:=m.mainDatabase.Directory; // tmp dir for session

  try
  initSongTable;
  except on E: Exception do
    showmessage('Error:initSongTable'+#13#10+E.Message);
  end;
  openTable(m.tableSong);

  try
  initSessionTable;
  except on E: Exception do
    showmessage('Error:initSessionTable'+#13#10+E.Message);
  end;
  openTable(m.tableSession);

end;

//========
procedure TplaytimeThread.initSongTable;
begin

	try
		with m.tableSong do
			begin
      DatabaseName:=m.query.databasename;
      TableName:='song.dat';
      Exclusive:=False;
      ReadOnly:=False;
			with FieldDefs do
				begin
				Clear;
				Add('id',ftAutoInc,0,True);
				Add('sessionid',ftInteger,0,False);
				Add('start',ftDateTime,0,False);
				Add('end',ftDateTime,0,False);
				Add('filename',ftMemo,0,False);
				Add('title',ftMemo,0,False);
				Add('bitrate',ftInteger,0,False);
				Add('samplerate',ftInteger,0,False);
				Add('channels',ftInteger,0,False);
				Add('filesize',ftInteger,0,False);
				Add('filedate',ftDateTime,0,False);
				Add('filetype',ftInteger,0,False);
				Add('drivetype',ftInteger,0,False);
				Add('heartbeatCount',ftInteger,0,False);
				Add('tracklength',ftInteger,0,False);
				Add('playlistIndex',ftInteger,0,False);
				Add('playlistCount',ftInteger,0,False);
				Add('skin',ftMemo,0,False);
				Add('shuffleOn',ftBoolean,0,False);
				Add('repeatOn',ftBoolean,0,False);
				Add('internetOn',ftBoolean,0,False);
				Add('equalizerOn',ftBoolean,0,False);
				Add('heartbeat',ftInteger,0,False);
				Add('heartbeatMin',ftInteger,0,False);
        Add('rating',ftInteger,0,False);
				end;
			with IndexDefs do
				begin
				Clear;
				Add('id','id',[ixPrimary,ixUnique,ixDescending]);
        Add('sessionid','sessionid',[ixDescending]);
				end;
			if not Exists then
				begin
				CreateTable;
				with RestructureFieldDefs do
					begin
					Clear;
					Add('id',ftAutoInc,0,True,'','','','',fcNoChange,1);
					Add('sessionid',ftInteger,0,False,'','','','',fcNoChange,2);
					Add('start',ftDateTime,0,False,'','','','',fcNoChange,3);
					Add('end',ftDateTime,0,False,'','','','',fcNoChange,4);
					Add('filename',ftMemo,0,False,'','','','',fcNoChange,5);
					Add('title',ftMemo,0,False,'','','','',fcNoChange,6);
					Add('bitrate',ftInteger,0,False,'','','','',fcNoChange,7);
					Add('samplerate',ftInteger,0,False,'','','','',fcNoChange,8);
					Add('channels',ftInteger,0,False,'','','','',fcNoChange,9);
					Add('filesize',ftInteger,0,False,'','','','',fcNoChange,10);
					Add('filedate',ftDateTime,0,False,'','','','',fcNoChange,11);
					Add('filetype',ftInteger,0,False,'','','','',fcNoChange,12);
					Add('drivetype',ftInteger,0,False,'','','','',fcNoChange,13);
					Add('heartbeatCount',ftInteger,0,False,'','','','',fcNoChange,14);
					Add('tracklength',ftInteger,0,False,'','','','',fcNoChange,15);
					Add('playlistIndex',ftInteger,0,False,'','','','',fcNoChange,16);
					Add('playlistCount',ftInteger,0,False,'','','','',fcNoChange,17);
					Add('skin',ftMemo,0,False,'','','','',fcNoChange,18);
					Add('shuffleOn',ftBoolean,0,False,'','','','',fcNoChange,19);
					Add('repeatOn',ftBoolean,0,False,'','','','',fcNoChange,20);
					Add('internetOn',ftBoolean,0,False,'','','','',fcNoChange,21);
					Add('equalizerOn',ftBoolean,0,False,'','','','',fcNoChange,22);
					Add('heartbeat',ftInteger,0,False,'','','','',fcNoChange,23);
					Add('heartbeatMin',ftInteger,0,False,'','','','',fcNoChange,24);
          Add('rating',ftInteger,0,False,'','','','',fcNoChange,25);
					end;
				with RestructureIndexDefs do
					begin
          // TODO : plugin has read/write access, parser has read only access?
          //        do some kind of locks have to be implemented?
          //        locks wouldnt work with the rater program if it was seperate and not included in playtime
					Clear;
					Add('id','id',[ixPrimary,ixUnique,ixDescending],icNone);
          Add('sessionid','sessionid',[ixDescending],icNone);
					end;
        // blob block size 64, and set table version to playtimeVersion
				RestructureTable(0,0,playtimeVersion,0,False,'','',64,-1,True);
				end;
			end;
  except
    on E: Exception do
    showmessage(e.message);
	end;

end;


//========
procedure TplaytimeThread.initSessionTable;
begin

	try
		with m.tableSession do
			begin
      DatabaseName:=m.query.databasename;
      TableName:='session.dat';
      Exclusive:=False;
      ReadOnly:=False;
			with FieldDefs do
				begin
				Clear;
				Add('id',ftAutoInc,0,True);
				Add('start',ftDateTime,0,False);
				Add('end',ftDateTime,0,False);
				Add('playtimeVersion',ftInteger,0,False);
				Add('winampVersion',ftInteger,0,False);
				end;
			with IndexDefs do
				begin
				Clear;
				Add('id','id',[ixPrimary,ixUnique,ixDescending]);
				end;
			if not Exists then
				begin
				CreateTable;
				with RestructureFieldDefs do
					begin
					Clear;
					Add('id',ftAutoInc,0,True,'','','','',fcNoChange,1);
					Add('start',ftDateTime,0,False,'','','','',fcNoChange,2);
					Add('end',ftDateTime,0,False,'','','','',fcNoChange,3);
					Add('playtimeVersion',ftInteger,0,False,'','','','',fcNoChange,4);
					Add('winampVersion',ftInteger,0,False,'','','','',fcNoChange,5);
					end;
				with RestructureIndexDefs do
					begin
					Clear;
					Add('id','id',[ixPrimary,ixUnique,ixDescending],icNone);
					end;
        // blob block size 64, and set table version to playtimeVersion
				RestructureTable(0,0,playtimeVersion,0,False,'','',64,-1,True);
				end;
			end;
  except
    on E: Exception do
    showmessage(e.message);
	end;

end;



//==============================================================================
procedure TrateThread.Execute;
begin
  while not(Terminated) do
  begin
    sleep(250);

    if Odd( GetAsyncKeystate( main.rateShortcut )) then
    begin
      if (
          // if systemwide
          ( main.rateSystemWide )
          or
          // if winamp is the foreground window...
          ( windows.getwindowthreadprocessid(windows.getforegroundwindow,nil) = windows.getwindowthreadprocessid(m.winamp.hwindow,nil) )
          ) then
          launchRatings;
    end;

  end;
end;

procedure TrateThread.launchRatings;
begin
  // QUIRK, launchRatings wont do anything until heartbeatMin is reached
  // if this song has been playing at least heartbeatMin beats

  // only works if heartbeatMin has PASSED, NOT >= otherwise there is the tiny chance of error since the playtimeThread gets data ON heartbeatMin
  if (playtimeThread.song.heartbeatCount > playtimeThread.song.heartbeatMin) then
  begin
    rateForm := TrateForm.CreateParented(application.handle);
    rateForm.showmodal;
    rateForm.free;
  end;
end;




end.
