unit aeLoaderManager;

interface

uses windows, types, System.Generics.Collections, aeGeometry, ae3DModelLoaderBase, aeLoader3DS, sysutils,
  aeLoaderAionCGF;

type
  TaeLoaderManagerResult = (AE_LOADERMANAGER_RESULT_SUCCESS, AE_LOADERMANAGER_RESULT_FAIL, AE_LOADERMANAGER_RESULT_FILE_NOT_SUPPORTED);

type
  TaeLoaderManager = class
  public
    constructor Create;
    function loadFromFile(file_name: string; var geo: TaeGeometry): TaeLoaderManagerResult;
  private
    _loaders: TList<Tae3DModelLoaderBase>;
    function getLoaderForFile(file_ext: string): Tae3DModelLoaderBase;
  end;

implementation

{ TaeLoaderManager }

constructor TaeLoaderManager.Create;
var
  loader: Tae3DModelLoaderBase;
begin
  self._loaders := TList<Tae3DModelLoaderBase>.Create;
  loader := TaeLoader3DS.Create;
  self._loaders.Add(loader);
  loader := TaeLoaderAionCGF.Create;
  self._loaders.Add(loader);
end;

function TaeLoaderManager.getLoaderForFile(file_ext: string): Tae3DModelLoaderBase;
var
  i: Integer;
begin
  for i := 0 to self._loaders.Count - 1 do
    if (self._loaders[i].getHandledFileExtension() = file_ext) then
    begin
      Result := self._loaders[i];
      exit;
    end;
end;

function TaeLoaderManager.loadFromFile(file_name: string; var geo: TaeGeometry): TaeLoaderManagerResult;
var
  f_ext: string;
  loader: Tae3DModelLoaderBase;
  f_load_result: boolean;
begin
  f_ext := ExtractFileExt(file_name);
  delete(f_ext, 1, 1); // remove dot
  loader := self.getLoaderForFile(f_ext);

  if (loader = nil) then
  begin
    Result := AE_LOADERMANAGER_RESULT_FILE_NOT_SUPPORTED;
    exit;
  end;

  case loader.getLoaderType of

    AE_LOADER_FILETYPE_3DS:
      f_load_result := TaeLoader3DS(loader).loadFromFile(file_name, geo);
    AE_LOADER_FILETYPE_AIONCGF:
      f_load_result := TaeLoaderAionCGF(loader).loadFromFile(file_name, geo);

  end;

  geo.SetNodeName(file_name);

  if (f_load_result) then
    Result := AE_LOADERMANAGER_RESULT_SUCCESS
  else
    Result := AE_LOADERMANAGER_RESULT_FAIL;

end;

end.
