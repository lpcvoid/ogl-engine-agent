unit aeLoaderAionH32;

(*
  This class loads an aion h32 heightmap.
*)

(*

  A few test vectors :

  X/Y/Z
  Z = height
  -- > calculated height

  1138.820435
  1082.670288
  135.8525238
  -->  135,699005126953

  1208.368896
  1033.267212
  140.8175659
  --> 140,753875732422


  1067.761353
  1009.945679
  136.7644653
  --> 136,75

  905.4499512
  1174.427002
  99.25
  --> 99,25 //perfect

  838.3372192
  1204.778687
  121.8994293
  --> 121,809242248535
*)
interface

uses aeHeightmapLoaderBase, windows, types, classes, sysutils;

type
  TaeLoaderAionH32 = class(TaeHeightmapLoaderBase)
  public
    Constructor Create(file_s: string); overload;
    Constructor Create(h32: Pointer; d_size: cardinal; remove_flag_byte: boolean = true); overload;
    function GetWord(x, y: cardinal): word; overload;
    function GetWord(indx: cardinal): word; overload;
    function GetData: PWord;
    function GetDataLength: cardinal;
    function GetSideLength: cardinal;
    // check if a point is below actual height; adjust it if it happens to be.
    procedure AdjustPointToHeight(var p: TPoint3D);
    function GetHeight(x, y: single): single; overload;
    function GetHeight(p: TPoint3D): single; overload;
  private
    // Remove the strange 3. byte in the file, we only need the height words.
    _sideLen: cardinal;
    _dataLen: cardinal;
    procedure ConvertData(h32: Pointer; d_size: cardinal);

  end;

implementation

{ TaeLoaderAionH32 }

procedure TaeLoaderAionH32.AdjustPointToHeight(var p: TPoint3D);
var
  h: single;
begin
  h := self.GetHeight(p);
  if (p.y < h) then
    p.y := h;
end;

procedure TaeLoaderAionH32.ConvertData(h32: Pointer; d_size: cardinal);
var
  nPoints, nRealPoints, sidelen: integer;
  realHeightMapData: PWord;
  i: integer;
begin

  Assert(((d_size mod 3) = 0), 'TaeLoaderAionH32.ConvertData() : h32 len not valid.');
  nPoints := d_size div 3;
  nRealPoints := nPoints * 2;
  GetMem(realHeightMapData, nRealPoints);
  for i := 0 to nPoints - 1 do
    PWord(cardinal(realHeightMapData) + (i * 2))^ := PWord(cardinal(h32) + (i * 3))^;
  self.AllocateMem(nRealPoints);
  self.SetHeightData(realHeightMapData, nRealPoints);
  FreeMem(realHeightMapData, nRealPoints);

  // calculate square root of length. Asm for speed.
  // this reults in the side.
  asm
    fild nPoints  // convert int to real, push to fpu stack
    fsqrt                   // square root of ST0
    fistp sidelen // convert back, pop from fpu stack
  end;

  self._sideLen := round(sqrt(nPoints));
  self._dataLen := nRealPoints;

end;

constructor TaeLoaderAionH32.Create(h32: Pointer; d_size: cardinal; remove_flag_byte: boolean = true);
begin
  self._loaderType := AE_LOADER_AION_H32;
  if (remove_flag_byte) then
    self.ConvertData(h32, d_size)
  else
  begin
    self.AllocateMem(d_size);
    self.SetHeightData(h32, d_size);
    self._sideLen := round(sqrt(d_size div 2));
    self._dataLen := d_size;
  end;
end;

constructor TaeLoaderAionH32.Create(file_s: string);
var
  ms: TMemoryStream;
begin
  Assert(FileExists(file_s), 'TaeLoaderAionH32.Create() : File doesn''t exist!');
  ms := TMemoryStream.Create;
  ms.LoadFromFile(file_s);
  self.ConvertData(ms.Memory, ms.Size);
  ms.Free;
end;

function TaeLoaderAionH32.GetData: PWord;
begin
  Result := PWord(self.GetHeightData());
end;

function TaeLoaderAionH32.GetDataLength: cardinal;
begin
  Result := self._dataLen;
end;

function TaeLoaderAionH32.GetHeight(x, y: single): single;
var
  xInt, yInt: cardinal;
  p1, p2, p3, p4, p13, p24, p1234: single;
begin
  x := x / 2.0;
  y := y / 2.0;
  xInt := round(x);
  yInt := round(y);
  p1 := self.GetWord(yInt + xInt * self._sideLen);
  p2 := self.GetWord(yInt + 1 + xInt * self._sideLen);
  p3 := self.GetWord(yInt + (xInt + 1) * self._sideLen);
  p4 := self.GetWord(yInt + 1 + (xInt + 1) * self._sideLen);
  p13 := p1 + (p1 - p3) * Frac(x); // frac(x) == (x mod 1.0)
  p24 := p2 + (p4 - p2) * Frac(x);
  p1234 := p13 + (p24 - p13) * Frac(y);
  Result := p1234 / 32.0;
end;

function TaeLoaderAionH32.GetHeight(p: TPoint3D): single;
begin
  if (p.x < self._sideLen * 2) and (p.x > 0) and (p.Z < self._sideLen * 2) and (p.Z > 0) then
    Result := self.GetHeight(p.x, p.Z);
end;

function TaeLoaderAionH32.GetSideLength: cardinal;
begin
  Result := self._sideLen;
end;

function TaeLoaderAionH32.GetWord(indx: cardinal): word;
begin
  if (indx < (self._dataLen div 2)) then
    Result := PWord(cardinal(self.GetData()) + indx * 2)^;
end;

function TaeLoaderAionH32.GetWord(x, y: cardinal): word;
begin
  Result := PWord(cardinal(self.GetData()) + (y + x * self._sideLen) * 2)^;
end;

end.
