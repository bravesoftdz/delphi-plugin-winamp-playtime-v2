unit vpopup;

interface

uses
  Windows, Forms, StdCtrls, Classes, Controls;

type
  TPopup = class(TForm)
    labelHint: TLabel;

    constructor Create(aHint: string); reintroduce;

    class procedure showpopup(aHint: string);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure labelHintClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  end;

var
  popup: TPopup;

implementation

{$R *.DFM}

class procedure TPopup.showpopup(aHint: string);
begin
  if not(aHint = '') then
    TPopup.Create(aHint);
end;

constructor TPopup.Create(aHint: string);
var
  point : TPoint;
  rectAvailable : TRect;
  sh, sw : integer;
begin
  inherited Create(nil);

  hint := aHint;
  labelHint.Caption := hint;

  GetCursorPos(point);
  left := point.x;
  top := point.y;

  SystemParametersInfo(SPI_GETWORKAREA, 0, @rectAvailable, 0);

  // if width + left > screenwidth, change left to screenwidth - width
  sw := rectAvailable.right - rectAvailable.left;
  sh := rectAvailable.bottom - rectAvailable.top;
  if (width + left > sw) then
    left := sw - width;
  // if height + top > screenheight, change top to screenheight - height
  if (height + top > sh) then
    top := sh - height;

  show;
end;

procedure TPopup.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  release;
end;

procedure TPopup.labelHintClick(Sender: TObject);
begin
  release;
end;

procedure TPopup.FormDeactivate(Sender: TObject);
begin
  release;
end;

end.
