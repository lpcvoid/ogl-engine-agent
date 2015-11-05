unit aeHeightmapLoaderBase;

(* Serves as a foundation class for loading heightmaps. *)

interface

uses windows, types;

type
  TaeHeightMapLoaderType = (AE_LOADER_AION_H32);

type
  TaeHeightmapLoaderBase = class
  public
    Constructor Create;
    Function GetHeightData: Pointer;
    Function GetHeightDataSize: integer;
    Function IsHeightDataSet: boolean;
    function GetLoaderType: TaeHeightMapLoaderType;

  protected
    _loaderType: TaeHeightMapLoaderType;
    procedure SetHeightData(p: Pointer; len: integer); overload;
    procedure AllocateMem(d_size: integer);
    Procedure FreeHeightData;
  private

    _data: Pointer; // pointer to the data.
    _dataLen: integer;
  end;

implementation

{ TaeHeightmapLoaderBase }

procedure TaeHeightmapLoaderBase.AllocateMem(d_size: integer);
begin
  self._data := AllocMem(d_size);
  self._dataLen := d_size;
end;

constructor TaeHeightmapLoaderBase.Create;
begin
  self._data := nil;
  self._dataLen := 0;
end;

procedure TaeHeightmapLoaderBase.FreeHeightData;
begin
  FreeMem(self._data, self._dataLen);
end;

function TaeHeightmapLoaderBase.GetHeightData: Pointer;
begin
  Result := self._data;
end;

function TaeHeightmapLoaderBase.GetHeightDataSize: integer;
begin
  Result := self._dataLen;
end;

function TaeHeightmapLoaderBase.GetLoaderType: TaeHeightMapLoaderType;
begin
  Result := self._loaderType;
end;

function TaeHeightmapLoaderBase.IsHeightDataSet: boolean;
begin
  Result := (self._dataLen > 0);
end;

procedure TaeHeightmapLoaderBase.SetHeightData(p: Pointer; len: integer);
begin
  CopyMemory(self._data, p, len);
  self._dataLen := len;
end;

end.
