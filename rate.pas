unit rate;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, vpopup,
  DBISAMTb, Db, dbisamen, CheckLst;

type
  TrateForm = class(TForm)
    buttonRate: TButton;
    query: TDBISAMQuery;
    buttonCancel: TButton;
    rateTableSong: TDBISAMTable;
    rateSession: TDBISAMSession;
    rateDatabase: TDBISAMDatabase;
    groupRating: TGroupBox;
    labelTitle: TLabel;
    rateBox: TCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure buttonRateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure buttonCancelClick(Sender: TObject);
    procedure rateBoxClickCheck(Sender: TObject);
    function rateSelected : integer;
    procedure rateBoxClick(Sender: TObject);
  public
    thisSongId: integer;
    thisSongRating: integer;
    thisSongTitle: string;
  end;

var
  rateForm: TrateForm;

implementation

{$R *.DFM}

uses main;

procedure TrateForm.FormCreate(Sender: TObject);
begin
  thisSongId := playtimeThread.song.id;
  thisSongRating := playtimeThread.song.rating;
  thisSongTitle := playtimeThread.song.title;

  labelTitle.Caption := thisSongTitle;

  rateDatabase.directory := dirPlaytime + '\' + main.logname;

  if not(thisSongRating = 0) then
    rateBox.State[10-thisSongRating] := cbChecked;

  with rateTableSong do
  begin
    TableName:='song.dat';
    Exclusive:=False;
    ReadOnly:=False;
    open;
  end;

end;

procedure TrateForm.buttonRateClick(Sender: TObject);
var
  currentRate : integer;
begin

  // ignore when no rating selected
  currentRate := rateSelected;
  if not(currentRate = 0) then
  begin
    with query do
    begin
      sql.text := 'update song set rating = :rating where id = :id';

      parambyname('rating').asInteger := currentRate;
      parambyname('id').asInteger := thisSongId;

      prepare;
      execsql;

      // update playtimeThread.song.rating ONLY if the current song is still playing
      if (thisSongId = playtimeThread.song.id) then
        playtimeThread.song.rating := currentRate;
    end;

    close;
  end;

end;

procedure TrateForm.buttonCancelClick(Sender: TObject);
begin
  close;
end;

procedure TrateForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  rateTableSong.close;
  rateTableSong.free;

  query.close;
  query.free;

  Action := caFree;

end;

function TrateForm.rateSelected : integer;
var
  i: integer;
begin
  Result := 0;
  for i:=0 to 9 do
  begin
    if (rateBox.state[i] = cbChecked) then
    begin
      // by 0 we mean 10 and by 9 we mean 1
      Result:=10-i;
      break;
    end;
  end;
end;

procedure TrateForm.rateBoxClickCheck(Sender: TObject);
var
  i: integer;
begin
  // uncheck all other checkboxes...
  with rateBox do
  begin
    for i:=0 to 9 do
    begin
      if not(i = itemIndex) then
        State[i] := cbUnchecked;
    end;
  end;
end;

// For some reason rateBoxClickCheck(Sender) doesn't work
// This just makes it so clicking the numbers also checks the checkboxes
// QUIRK: This makes it tough to unclick a checked box, but it's worth it
procedure TrateForm.rateBoxClick(Sender: TObject);
var
  i: integer;
begin
  // uncheck all other checkboxes...
  with rateBox do
  begin
    for i:=0 to 9 do
    begin
      if not(i = itemIndex) then
        State[i] := cbUnchecked
      else
        State[i] := cbChecked;
    end;
  end;
end;

end.
