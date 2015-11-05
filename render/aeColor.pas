unit aeColor;

interface

uses types, classes, graphics;

type
  TaeColorCode = array [0 .. 2] of byte;

type
  TaeColor = class
  public
    constructor Create(r, g, b: byte); overload;
    constructor Create; overload;
    procedure setColor(r, g, b: byte); overload;
    procedure setColor(c: TColor); overload;
    procedure setColor(c: TaeColorCode); overload;
    function getColor: TaeColorCode;
    function getRed(): byte;
    function getGreen(): byte;
    function getBlue(): byte;
    procedure setRandomColor();
  private
    _color: TaeColorCode;

  end;

implementation

{ TaeColor }

constructor TaeColor.Create;
begin
  self._color[0] := 255;
  self._color[1] := 255;
  self._color[2] := 255;
end;

function TaeColor.getBlue: byte;
begin
  result := self._color[2];
end;

function TaeColor.getColor: TaeColorCode;
begin
  result := self._color;
end;

function TaeColor.getGreen: byte;
begin
  result := self._color[1];
end;

function TaeColor.getRed: byte;
begin
  result := self._color[0];
end;

procedure TaeColor.setColor(c: TaeColorCode);
begin
  self._color := c;
end;

procedure TaeColor.setRandomColor;
begin
  self._color[0] := Random(255);
  self._color[1] := Random(255);
  self._color[2] := Random(255);
end;

procedure TaeColor.setColor(c: TColor);
var
  winColor: Integer;
begin
  // Delphi color to Windows color
  winColor := ColorToRGB(c);
  // convert 0..255 range into 0..1 range
  self._color[0] := (winColor and $FF);
  self._color[1] := ((winColor shr 8) and $FF);
  self._color[2] := ((winColor shr 16) and $FF);
end;

constructor TaeColor.Create(r, g, b: byte);
begin
  self._color[0] := r;
  self._color[1] := g;
  self._color[2] := b;
end;

procedure TaeColor.setColor(r, g, b: byte);
begin
  self._color[0] := r;
  self._color[1] := g;
  self._color[2] := b;
end;

end.
